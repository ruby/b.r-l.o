module RedmineS3
  module AttachmentsControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        before_filter :find_attachment_s3, :only => [:show, :download, :thumbnail]
        before_filter :find_editable_attachments_s3, :only => [:edit, :update]
        skip_before_filter :file_readable
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def find_attachment_s3
        if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
          @attachment.increment_download
        end
        if RedmineS3::Connection.proxy?
          send_data RedmineS3::Connection.get(@attachment.disk_filename),
                                          :filename => filename_for_content_disposition(@attachment.filename),
                                          :type => detect_content_type(@attachment),
                                          :disposition => (@attachment.image? ? 'inline' : 'attachment')
        else
          redirect_to(RedmineS3::Connection.object_url(@attachment.disk_filename))
        end
      end

      def find_editable_attachments_s3
        if @attachments
          @attachments.each { |a| a.increment_download }
        end
        if RedmineS3::Connection.proxy?
          @attachments.each do |attachment|
            send_data RedmineS3::Connection.get(attachment.disk_filename),
                                            :filename => filename_for_content_disposition(attachment.filename),
                                            :type => detect_content_type(attachment),
                                            :disposition => (attachment.image? ? 'inline' : 'attachment')
          end
        end
      end
    end
  end
end
