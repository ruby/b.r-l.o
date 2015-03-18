module RedmineS3
  module ApplicationHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        alias_method_chain :thumbnail_tag, :s3_patch
      end
    end

    module InstanceMethods
      def thumbnail_tag_with_s3_patch(attachment)
        link_to image_tag(attachment.thumbnail_s3),
                RedmineS3::Connection.object_url(attachment.disk_filename_s3),
                :title => attachment.filename
      end
    end
  end
end