require 'net/imap'
require 'yaml'
require "aws-sdk-s3"
require "mail"
require "stringio"

module RedmineMailingListIntegrationImapSupplement
  module IMAP
    module_function

    def config
      @@config ||= YAML.load(ERB.new(Rails.root.join("config/imap.yml").read).result)
    end

    def with_connection(name)
      config = self.config[name]
      raise ArgumentError, "no such configuration: '#{name}'" if config.nil?

      config = config.with_indifferent_access
      host = config[:host] || '127.0.0.1'
      port = config[:port] || '143'
      ssl = !config[:ssl].nil?
      folder = config[:folder] || 'INBOX'
      imap = Net::IMAP.new(host, port, ssl)
      begin
        imap.login(config[:username], config[:password]) unless config[:username].nil?
        imap.select(folder)
        yield imap, config
      ensure
        imap.disconnect
      end
    end

    def fetch(storage_name, query, session = nil)
      if session.nil?
        with_connection(storage_name) do |session, config|
          session.search(query).map do |seqno|
            session.fetch(seqno, 'RFC822')[0]
          end
        end
      else
        session.search(query).map do |seqno|
          session.fetch(seqno, 'RFC822')[0]
        end
      end
    end

    def receive(storage_name, query)
      with_connection(storage_name) do |session, config|
        fetch(storage_name, query, session).each do |data|
          msg = data.attr['RFC822']
          seqno = data.seqno
          if MailHandler.receive(msg, unknown_user: "accept", no_permission_check: '1') && record_s3(msg)
            logger.debug "Message #{seqno} successfully received" if logger && logger.debug?
            session.store(seqno, "+FLAGS", [:Seen])
          else
            logger.debug "Message #{seqno} can not be processed #{msg}" if logger && logger.debug?
            session.store(seqno, "+FLAGS", [:Seen, :Flagged])
          end
        end
      end
    end

    def check(storage_name = nil)
      targets = storage_name.nil? ? config.keys : [storage_name.to_s]
      targets.each do |name|
        receive(name, ['NOT', 'SEEN'])
      end
    end

    def record_s3(msg)
      m = Mail.new(msg)
      list_name = m.header['List-Id'].to_s.match(/\<(.*)\.ml\.ruby\-lang\.org\>/)
      list_name = list_name && list_name[1]
      post_id = m.header["Subject"].to_s.match(/\[#{list_name}:(\d+)\].*/)
      post_id = post_id && post_id[1]

      from = begin
        m.header["from"].to_s.gsub(/@[a-zA-Z.\-]+/, "@...")
      rescue
        m.header['from']
      end
      io = StringIO.new
      io.puts "From: #{from}"
      io.puts "Date: #{m.date}"
      begin
        io.puts "Subject: #{m.subject}"
      rescue Encoding::CompatibilityError
        io.puts "Subject: "
      end
      io.puts ""
      io.puts m.body.to_s.encode("UTF-8", "ISO-2022-JP", invalid: :replace, undef: :replace)

      s3 = Aws::S3::Resource.new(
        region: 'ap-northeast-1',
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )
      bucket = s3.bucket('blade.ruby-lang.org')
      bucket.object("#{list_name}/#{post_id}").put(body: io.string)
    ensure
      io.close
    end

    def logger
      Rails.logger
    end
  end
end
