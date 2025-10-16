# frozen_string_literal: true

class IpBlockMiddleware
  def initialize(app, options = {})
    @app = app
    @blocked_ips = load_blocked_ips || []
    @logger = options[:logger] || Rails.logger
  end

  def call(env)
    request = Rack::Request.new(env)
    client_ip = request.ip

    if blocked?(client_ip)
      @logger.info "Blocked request from IP: #{client_ip}"
      [
        403, 
        { 'Content-Type' => 'text/plain' },
        ["Access from your IP address (#{client_ip}) has been blocked. Please contact https://github.com/ruby/b.r-l.o/issue if you believe this is a mistake."]
      ]
    else
      @app.call(env)
    end
  end

  private

  def load_blocked_ips
    config_file = File.join(Rails.root, 'config', 'ban_ip.yml')
    if File.exist?(config_file)
      begin
        yaml = YAML.load(ERB.new(File.read(config_file)).result)
        env = Rails.env
        conf = {}
        if yaml.is_a?(Hash)
          if yaml['default']
            conf.merge!(yaml['default'])
          end
          if yaml[env]
            conf.merge!(yaml[env])
          end
        end
        conf['blocked_ips']
      rescue => e
        Rails.logger.error "Error loading ban_ip.yml configuration: #{e.message}"
        []
      end
    else
      Rails.logger.warn "IP blocking configuration file (ban_ip.yml) not found"
      []
    end
  end

  def blocked?(ip)
    @blocked_ips.any? do |blocked_ip|
      if blocked_ip.include?('/')
        # Handle CIDR notation (e.g. 192.168.1.0/24)
        cidr_match?(ip, blocked_ip)
      else
        # Simple IP comparison
        ip == blocked_ip
      end
    end
  end

  def cidr_match?(ip, cidr)
    require 'ipaddr'
    begin
      IPAddr.new(cidr).include?(IPAddr.new(ip))
    rescue ArgumentError => e
      @logger.error "Invalid IP address format: #{e.message}"
      false
    end
  end
end
