require 'net/imap'
require 'yaml'

module RedmineMailingListIntegrationIMAPSupplement
  module IMAP
    module_function
    def config
      @@config ||= YAML.load_file(File.join(RAILS_ROOT, "config/imap.yaml"))
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
        with_connection(storage_name){|session,config|
          session.search(query).map do |seqno|
            session.fetch(seqno, 'RFC822')[0]
          end
        }
      else
        session.search(query).map do |seqno|
          session.fetch(seqno, 'RFC822')[0]
        end
      end
    end

    def receive(storage_name, query)
      with_connection(storage_name){|session,config|
        fetch(storage_name, query, session).each do |data|
          msg = data.attr['RFC822']
          seqno = data.seqno
          if MailHandler.receive(msg, :unknown_user => "accept", :no_permission_check => '1')
            logger.debug "Message #{seqno} successfully received" if logger && logger.debug?
            session.store(seqno, "+FLAGS", [:Seen])
          else
            logger.debug "Message #{seqno} can not be processed" if logger && logger.debug?
            session.store(seqno, "+FLAGS", [:Seen, :Flagged])
          end
        end
      }
    end

    def check(storage_name = nil)
      targets = storage_name.nil? ? config.keys : [storage_name.to_s]
      targets.each do |name|
        receive(name, ['NOT', 'SEEN'])
      end
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end
