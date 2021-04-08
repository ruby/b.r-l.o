require 'redmine_s3'

require_dependency 'redmine_s3_hooks'

Redmine::Plugin.register :redmine_s3 do
  name 'S3'
  author 'Chris Dell'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'
end
