module RedmineS3
  module AttachmentPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        attr_accessor :s3_access_key_id, :s3_secret_acces_key, :s3_bucket, :s3_bucket
        after_validation :put_to_s3
        before_destroy   :delete_from_s3
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def put_to_s3
        if @temp_file && (@temp_file.size > 0)
          self.disk_filename = Attachment.disk_filename(filename) if disk_filename.blank?
          logger.debug("Uploading to #{disk_filename}")
          content = @temp_file.respond_to?(:read) ? @temp_file.read : @temp_file
          RedmineS3::Connection.put(disk_filename, content, self.content_type)
          md5 = Digest::MD5.new
          self.digest = md5.hexdigest
        end
        @temp_file = nil # so that the model's original after_save block skips writing to the fs
      end

      def delete_from_s3
        logger.debug("Deleting #{disk_filename}")
        RedmineS3::Connection.delete(disk_filename)
      end

      # Prevent file uploading to the file system to avoid change file name
      def files_to_final_location; end

      # Returns the full path the attachment thumbnail, or nil
      # if the thumbnail cannot be generated.
      def thumbnail_s3(options={})
        return nil unless Object.const_defined?(:Magick)
        if thumbnailable?
          size = options[:size].to_i
          if size > 0
            # Limit the number of thumbnails per image
            size = (size / 50) * 50
            # Maximum thumbnail size
            size = 800 if size > 800
          else
            size = Setting.thumbnails_size.to_i
          end
          size         = 100 unless size > 0
          target       = "#{id}_#{digest}_#{size}.thumb"
          target       = File.join(RedmineS3::Connection.thumb_folder, target) unless RedmineS3::Connection.thumb_folder.blank?
          update_thumb = options[:update_thumb] || false
          begin
            RedmineS3::ThumbnailPatch.generate_s3_thumb(self.disk_filename, target, size, update_thumb)
          rescue => e
            logger.error "An error occured while generating thumbnail for #{disk_filename} to #{target}\nException was: #{e.message}" if logger
            return nil
          end
        end
      end
    end
  end
end
