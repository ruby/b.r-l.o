curr_dirname = File.dirname(__FILE__)
%w(
  attachments_controller_patch
  attachment_patch import_patch
  pdf_patch thumbnail_patch utils_patch
  connection
).each do |require_file|
  require File.join(curr_dirname, 'lib', 'redmica_s3', require_file)
end

Redmine::Plugin.register :redmica_s3 do
  name 'RedMica S3 plugin'
  description 'Use Amazon S3 as a storage engine for attachments'
  url 'https://github.com/redmica/redmica_s3'
  author 'Far End Technologies Corporation'
  author_url 'https://www.farend.co.jp'

  version '1.0.12'
  requires_redmine version_or_higher: '4.1.0'

  Redmine::Thumbnail.__send__(:include, RedmicaS3::ThumbnailPatch)
  Redmine::Utils.__send__(:include, RedmicaS3::UtilsPatch)
  Attachment.__send__(:include, RedmicaS3::AttachmentPatch)
  Redmine::Export::PDF::ITCPDF.__send__(:include, RedmicaS3::PdfPatch)
  Import.__send__(:include, RedmicaS3::ImportPatch)
  AttachmentsController.__send__(:include, RedmicaS3::AttachmentsControllerPatch)

  RedmicaS3::Connection.create_bucket
end
