module RedmicaS3
  module ImportPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
      end

      # Returns the relative path of the file to import
      def filepath
        File.join(RedmicaS3::Connection.import_folder.presence, self.filename.presence) if super
      end

      # Returns true if the file to import exists
      def file_exists?
        filepath.present? && s3_object(false).exists?
      end

      private

      # Reads lines from the beginning of the file, up to the specified number
      # of bytes (max_read_bytes).
      def read_file_head(max_read_bytes = 4096)
        return '' unless file_exists?
        return s3_object.get.body.read if s3_object.content_length <= max_read_bytes
        # The last byte of the chunk may be part of a multi-byte character,
        # causing an invalid byte sequence. To avoid this, it truncates
        # the chunk at the last LF character, if found.
        chunk = s3_object.get.body.read(max_read_bytes)
        last_lf_index = chunk.rindex("\n")
        last_lf_index ? chunk[..last_lf_index] : chunk
      end

      def read_rows
        return unless file_exists?

        from_encoding = settings['encoding'].to_s.presence || 'UTF-8'
        raw = s3_object.get.body.read
        if from_encoding == 'UTF-8'
          raw = raw[1..-1] if raw[0] == "\ufeff"  # Remove BOM
        end
        raw.encode!(Encoding::UTF_8, from_encoding)

        csv_options = {:headers => false}
        separator = settings['separator'].to_s
        csv_options[:col_sep] = separator if separator.size == 1
        wrapper = settings['wrapper'].to_s
        csv_options[:quote_char] = wrapper if wrapper.size == 1

        CSV.parse(raw, **csv_options) do |row|
          yield row if block_given?
        end
      end

      # Deletes the import file
      def remove_file
        return unless file_exists?

        s3_object(false).delete
      rescue => e
        Rails.logger.error "Unable to delete file #{self.filename}: #{e.message}"
      end

    end

  protected

    def s3_object(reload = true)
      object = RedmicaS3::Connection.object(filepath, nil)
      object.reload if reload && !object.data_loaded?
      object
    end

  end
end
