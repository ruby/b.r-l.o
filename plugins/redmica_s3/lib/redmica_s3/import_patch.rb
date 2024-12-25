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

      def set_default_settings(options={})
        separator = lu(user, :general_csv_separator)
        if file_exists?
          begin
            content = s3_object.get.body.read(256)
            separator = [',', ';'].sort_by {|sep| content.count(sep) }.last
          rescue => e
          end
        end
        wrapper = '"'
        encoding = lu(user, :general_csv_encoding)

        date_format = lu(user, "date.formats.default", :default => "foo")
        date_format = self.class::DATE_FORMATS.first unless self.class::DATE_FORMATS.include?(date_format)

        self.settings.merge!(
          'separator' => separator,
          'wrapper' => wrapper,
          'encoding' => encoding,
          'date_format' => date_format,
          'notifications' => '0'
        )

        if options.key?(:project_id) && !options[:project_id].blank?
          # Do not fail if project doesn't exist
          begin
            project = Project.find(options[:project_id])
            self.settings.merge!('mapping' => {'project_id' => project.id})
          rescue; end
        end
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