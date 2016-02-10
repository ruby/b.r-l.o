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
        after_create      :generate_thumbnail_s3
        before_destroy   :delete_from_s3
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def put_to_s3
        if @temp_file && (@temp_file.size > 0) && errors.blank?
          self.disk_directory = disk_directory || target_directory
          self.disk_filename  = Attachment.disk_filename(filename, disk_directory) if disk_filename.blank?
          logger.debug("Uploading to #{disk_filename}")
          content = @temp_file.respond_to?(:read) ? @temp_file.read : @temp_file
          RedmineS3::Connection.put(disk_filename_s3, filename, content, self.content_type)
          md5 = Digest::MD5.new
          md5.update(content)
          self.digest = md5.hexdigest
        end
        @temp_file = nil # so that the model's original after_save block skips writing to the fs
      end

      def delete_from_s3
        logger.debug("Deleting #{disk_filename_s3}")
        RedmineS3::Connection.delete(disk_filename_s3)
      end

      # Prevent file uploading to the file system to avoid change file name
      def files_to_final_location; end

      # Returns the full path the attachment thumbnail, or nil
      # if the thumbnail cannot be generated.
      def thumbnail_s3(options = {})
        return unless thumbnailable?
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
        update_thumb = options[:update_thumb] || false
        begin
          RedmineS3::ThumbnailPatch.generate_s3_thumb(self.disk_filename_s3, target, size, update_thumb)
        rescue => e
          logger.error "An error occured while generating thumbnail for #{disk_filename_s3} to #{target}\nException was: #{e.message}" if logger
          return
        end
      end

      def disk_filename_s3
        path = disk_filename
        path = File.join(disk_directory, path) unless disk_directory.blank?
        path
      end

      def generate_thumbnail_s3
        thumbnail_s3(update_thumb: true)
      end
    end
  end
end
