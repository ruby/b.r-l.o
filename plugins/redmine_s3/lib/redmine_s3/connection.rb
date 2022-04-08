require 'aws-sdk-s3'

module RedmineS3
  class Connection
    @@conn = nil
    @@s3_options = {
      :access_key_id     => nil,
      :secret_access_key => nil,
      :bucket            => nil,
      :folder            => '',
      :endpoint          => nil,
      :port              => nil,
      :ssl               => nil,
      :private           => false,
      :expires           => nil,
      :secure            => false,
      :proxy             => false,
      :thumb_folder      => 'tmp'
    }

    class << self
      def load_options
        file = ERB.new( File.read(File.join(Rails.root, 'config', 's3.yml')) ).result
        YAML::load( file )[Rails.env].each do |key, value|
          @@s3_options[key.to_sym] = value
        end
      end

      def establish_connection
        load_options unless @@s3_options[:access_key_id] && @@s3_options[:secret_access_key]
        options = {
          :access_key_id => @@s3_options[:access_key_id],
          :secret_access_key => @@s3_options[:secret_access_key]
        }
        options[:s3_endpoint] = self.endpoint unless self.endpoint.nil?
        options[:s3_port] = self.port unless self.port.nil?
        options[:use_ssl] = self.ssl unless self.ssl.nil?
        @conn = Aws::S3::Resource.new(options)
      end

      def conn
        @@conn || establish_connection
      end

      def bucket
        load_options unless @@s3_options[:bucket]
        @@s3_options[:bucket]
      end

      def create_bucket
        bucket = self.conn.bucket(self.bucket)
        self.conn.create_bucket({bucket: self.bucket}) unless bucket.exists?
      end

      def folder
        str = @@s3_options[:folder]
        if str.present?
          str.match(/\S+\//) ? str : "#{str}/"
        else
          ''
        end
      end

      def endpoint
        @@s3_options[:endpoint]
      end

      def port
        @@s3_options[:port]
      end

      def ssl
        @@s3_options[:ssl]
      end

      def expires
        @@s3_options[:expires]
      end

      def private?
        @@s3_options[:private]
      end

      def secure?
        @@s3_options[:secure]
      end

      def proxy?
        @@s3_options[:proxy]
      end

      def thumb_folder
        str = @@s3_options[:thumb_folder]
        if str.present?
          str.match(/\S+\//) ? str : "#{str}/"
        else
          'tmp/'
        end
      end

      def object(filename, target_folder = self.folder)
        bucket = self.conn.bucket(self.bucket)
        bucket.object(target_folder + filename)
      end

      def put(disk_filename, original_filename, data, content_type='application/octet-stream', target_folder = self.folder)
        object = self.object(disk_filename, target_folder)
        options = {}
        options[:acl] = "public-read" unless self.private?
        options[:content_type] = content_type if content_type
        options[:content_disposition] = "inline; filename=#{ERB::Util.url_encode(original_filename)}"
        object.put({body: data}.merge(options))
      end

      def delete(filename, target_folder = self.folder)
        object = self.object(filename, target_folder)
        object.delete
      end

      def object_url(filename, target_folder = self.folder)
        object = self.object(filename, target_folder)
        if self.private?
          options = {}
          options[:expire_in] = self.expires unless self.expires.nil?
          object.presigned_url(:get, options)
        else
          object.public_url
        end
      end

      def get(filename, target_folder = self.folder)
        object = self.object(filename, target_folder)
        object.get.body.read
      end
    end
  end
end
