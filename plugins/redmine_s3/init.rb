require 'redmine_s3'

Redmine::Plugin.register :redmine_s3_attachments do
  name 'S3'
  author 'Chris Dell'
  description 'Use Amazon S3 as a storage engine for attachments'
  version '0.0.3'
end
