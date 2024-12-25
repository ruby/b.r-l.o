require 'timeout'

module RedmicaS3
  module ThumbnailPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
      def batch_delete!(target_prefix = nil)
        prefix = File.join(RedmicaS3::Connection.thumb_folder, "#{target_prefix}")

        bucket = RedmicaS3::Connection.__send__(:own_bucket)
        bucket.objects({prefix: prefix}).batch_delete!
        return
      end
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
        # Generates a thumbnail for the source image to target
        def generate(source, target, size, is_pdf = false)
          return nil unless convert_available?
          return nil if is_pdf && !gs_available?

          target_folder = RedmicaS3::Connection.thumb_folder
          object = RedmicaS3::Connection.object(target, target_folder)
          unless object.exists?
            return nil unless Object.const_defined?(:MiniMagick)

            raw_data = RedmicaS3::Connection.object(source).reload.get.body.read rescue nil
            mime_type = Marcel::MimeType.for(raw_data)
            return nil if !Redmine::Thumbnail::ALLOWED_TYPES.include? mime_type
            return nil if is_pdf && mime_type != "application/pdf"

            size_option = "#{size}x#{size}>"
            begin
              extname_source = File.extname(source)
              tempfile = MiniMagick::Utilities.tempfile(extname_source) do |f| f.write(raw_data) end
              output_tempfile = MiniMagick::Utilities.tempfile(is_pdf ? ".png" : extname_source)
              in_filepath = tempfile.path
              out_filepath = output_tempfile.path
              # Generate command
              convert =
                if MiniMagick.version < Gem::Version.new('5.0.0')
                  MiniMagick::Tool::Convert.new # MiniMagick::Tool::Convert is deprecated in MiniMagick 5.0.0
                else
                  MiniMagick.convert
                end
              if is_pdf
                convert << "#{in_filepath}[0]"
                convert.thumbnail size_option
                convert << "png:#{out_filepath}"
              else
                convert << in_filepath
                convert.auto_orient
                convert.thumbnail size_option
                convert << out_filepath
              end
              # Execute command (Note: Timeout control reuses code from Redmine itself)
              timeout = Redmine::Configuration['thumbnails_generation_timeout'].to_i
              timeout = nil if timeout <= 0
              pid = nil
              cmd = convert.command
              Timeout.timeout(timeout) do
                pid = Process.spawn(*cmd)
                _, status = Process.wait2(pid)
                unless status.success?
                  Rails.logger.error("Creating thumbnail failed (#{status.exitstatus}):\nCommand: #{cmd.join(' ')}")
                  return nil
                end
              end
              img_blob = File.binread(out_filepath)
              mime_type = Marcel::MimeType.for(img_blob)
              sha = Digest::SHA256.new
              sha.update(img_blob)
              new_digest = sha.hexdigest
              RedmicaS3::Connection.put(target, File.basename(target), img_blob, mime_type,
                {target_folder: target_folder, digest: new_digest}
              )
            rescue Timeout::Error
              Process.kill('KILL', pid) if pid
              Rails.logger.error("Creating thumbnail timed out:\nCommand: #{cmd.join(' ')}")
              return nil
            rescue => e
              Rails.logger.error("Creating thumbnail failed (#{e.message}):")
              return nil
            ensure
              tempfile.unlink if tempfile
              output_tempfile.unlink if output_tempfile
            end
          end

          object.reload
          [object.metadata['digest'], object.get.body.read]
        end
      end
    end
  end
end
