module RedmineS3
  module AttachmentsControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        before_filter :find_attachment_s3, :only => [:show]
        before_filter :download_attachment_s3, :only => [:download]
        before_filter :find_thumbnail_attachment_s3, :only => [:thumbnail]
        before_filter :find_editable_attachments_s3, :only => [:edit, :update]
        skip_before_filter :file_readable
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def find_attachment_s3
        if @attachment.is_diff?
          @diff = RedmineS3::Connection.get(@attachment.disk_filename_s3)
          @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
          @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
          # Save diff type as user preference
          if User.current.logged? && @diff_type != User.current.pref[:diff_type]
            User.current.pref[:diff_type] = @diff_type
            User.current.preference.save
          end
          render :action => 'diff'
        elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
          @content = RedmineS3::Connection.get(@attachment.disk_filename_s3)
          render :action => 'file'
        else
          download_attachment_s3
        end
      end

      def download_attachment_s3
        if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
          @attachment.increment_download
        end
        if RedmineS3::Connection.proxy?
          send_data RedmineS3::Connection.get(@attachment.disk_filename_s3),
                                          :filename => filename_for_content_disposition(@attachment.filename),
                                          :type => detect_content_type(@attachment),
                                          :disposition => (@attachment.image? ? 'inline' : 'attachment')
        else
          redirect_to(RedmineS3::Connection.object_url(@attachment.disk_filename_s3))
        end
      end

      def find_editable_attachments_s3
        if @attachments
          @attachments.each { |a| a.increment_download }
        end
        if RedmineS3::Connection.proxy?
          @attachments.each do |attachment|
            send_data RedmineS3::Connection.get(attachment.disk_filename_s3),
                                            :filename => filename_for_content_disposition(attachment.filename),
                                            :type => detect_content_type(attachment),
                                            :disposition => (attachment.image? ? 'inline' : 'attachment')
          end
        end
      end

      def find_thumbnail_attachment_s3
        update_thumb = 'true' == params[:update_thumb]
        url          = @attachment.thumbnail_s3(update_thumb: update_thumb)
        return render json: {src: url} if update_thumb
        return if url.nil?
        if RedmineS3::Connection.proxy?
          send_data RedmineS3::Connection.get(url, ''),
                    :filename => filename_for_content_disposition(@attachment.filename),
                    :type => detect_content_type(@attachment),
                    :disposition => (@attachment.image? ? 'inline' : 'attachment')
        else
          redirect_to(url)
        end
      end
    end
  end
end
