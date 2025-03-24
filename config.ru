# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Rack::Protection::HttpOrigin
use Rack::Protection::FrameOptions

# Block IP from config/ban_ip.yml
use IpBlockMiddleware if Rails.env.production?

use YjitStatsMiddleware if Rails.env.production?

run Rails.application
