# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Rack::Protection::HttpOrigin
use Rack::Protection::FrameOptions
use YjitStatsMiddleware if Rails.env.production?

run Rails.application
