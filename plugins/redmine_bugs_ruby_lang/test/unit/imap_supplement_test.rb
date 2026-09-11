# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class ImapSupplementTest < ActiveSupport::TestCase
  def setup
    @s3 = Aws::S3::Resource.new(stub_responses: true)
    Aws::S3::Resource.stubs(:new).returns(@s3)
  end

  def test_list_post_is_archived_in_both_buckets
    record_s3(<<~MAIL)
      List-Id: <ruby-core.ml.ruby-lang.org>
      Subject: [ruby-core:123456] [Ruby Feature#1] Hello

      body
    MAIL

    assert_equal [['blade-data-vault', 'ruby-core/123456'], ['blade.ruby-lang.org', 'ruby-core/123456']], archived_keys
  end

  def test_mail_outside_mailing_lists_is_not_archived
    record_s3(<<~MAIL)
      Subject: Security alert

      body
    MAIL

    assert_empty archived_keys
  end

  def test_list_notice_without_post_number_is_not_archived
    record_s3(<<~MAIL)
      List-Id: <ruby-core.ml.ruby-lang.org>
      Subject: Your message to ruby-core awaits moderator approval

      body
    MAIL

    assert_empty archived_keys
  end

  private

  def record_s3(msg)
    RedmineMailingListIntegrationImapSupplement::IMAP.record_s3(msg)
  end

  def archived_keys
    @s3.client.api_requests.map {|req| req[:params].values_at(:bucket, :key)}
  end
end
