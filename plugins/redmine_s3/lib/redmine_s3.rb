require 'redmine_s3/attachment_patch'
require 'redmine_s3/attachments_controller_patch'
require 'redmine_s3/application_helper_patch'
require 'redmine_s3/thumbnail_patch'
require 'redmine_s3/connection'

AttachmentsController.send(:include, RedmineS3::AttachmentsControllerPatch)
Attachment.send(:include, RedmineS3::AttachmentPatch)
ApplicationHelper.send(:include, RedmineS3::ApplicationHelperPatch)
RedmineS3::Connection.create_bucket
