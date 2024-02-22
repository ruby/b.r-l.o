module RedmicaS3
  module UtilsPatch
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
        def save_upload(upload, path)
          default_external, default_internal = Encoding.default_external, Encoding.default_internal
          Encoding.default_external = Encoding::ASCII_8BIT
          Encoding.default_internal = Encoding::ASCII_8BIT
          object = RedmicaS3::Connection.object(path, nil)
          if upload.respond_to?(:read)
            object.upload_stream do |write_stream|
              buffer = ""
              while (buffer = upload.read(8192))
                write_stream << buffer.b
                yield buffer if block_given?
              end
            end
          else
            object.write(upload)
            yield upload if block_given?
          end
        ensure
          Encoding.default_external = default_external
          Encoding.default_internal = default_internal
        end
      end
    end
  end
end