module RedmineS3
  module ThumbnailPatch
    # Generates a thumbnail for the source image to target
    def self.generate_s3_thumb(source, target, size, update_thumb = false)
      return nil unless Object.const_defined?(:Magick)
      target_folder = RedmineS3::Connection.thumb_folder
      if update_thumb
        require 'open-uri'
        img = Magick::ImageList.new
        url = RedmineS3::Connection.object_url(source)
        open(url, 'rb') do |f| img = img.from_blob(f.read) end
        img = img.strip!
        img = img.resize_to_fit(size)

        RedmineS3::Connection.put(target, File.basename(target), img.to_blob, img.mime_type, target_folder)
      end
      RedmineS3::Connection.object_url(target, target_folder)
    end
  end
end
