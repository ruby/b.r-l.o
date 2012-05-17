require 'redmine_s3/attachment_patch'
require 'redmine_s3/attachments_controller_patch'
require 'redmine_s3/connection'

AttachmentsController.send(:include, RedmineS3::AttachmentsControllerPatch)
Attachment.send(:include, RedmineS3::AttachmentPatch)
RedmineS3::Connection.create_bucket
