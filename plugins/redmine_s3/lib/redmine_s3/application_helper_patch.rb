module RedmineS3
  module ApplicationHelperPatch
    extend ActiveSupport::Concern

    included do # :nodoc:
      prepend S3Thumbnail
    end

    module S3Thumbnail
      def thumbnail_tag(attachment)
        link_to image_tag(attachment.thumbnail_s3, data: {thumbnail: thumbnail_path(attachment)}),
                RedmineS3::Connection.object_url(attachment.disk_filename_s3),
                title: attachment.filename
      end
    end
  end
end
