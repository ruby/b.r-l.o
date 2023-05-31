require "mail"

module RedmineRubyLangMailingListCustomization
  module RedmineExt
    module Mailer
      def issue_add(user, issue)
        m = super(user, issue)

        m.header[:subject] = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}] #{issue.subject}"
        m
      end

      def issue_edit(user, journal)
        issue = journal.issue
        m = super(user, journal)

        m.header[:subject] = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}] #{issue.subject}"
        m
      end

      def mail(headers={}, &block)
        from_addr = headers[:to].to_s
        case from_addr
        when "ruby-dev@ruby-lang.org" then from_addr = "ruby-dev@ml.ruby-lang.org"
        when "ruby-core@ruby-lang.org" then from_addr = "ruby-core@ml.ruby-lang.org"
        # otherwise, keep it as is (e.g., "noreply@ruby-lang.org")
        end
        mail_from = Mail::Address.new(from_addr)
        if mail_from.display_name.blank? && mail_from.comments.blank?
          mail_from.display_name = @author&.logged? ? @author.name : Setting.app_title
        end
        headers[:from] = mail_from.format
        headers[:bcc] = (headers[:bcc] || []).concat((headers[:cc] || []))
        headers[:cc] = []
        headers[:charset] = "utf-8"
        locale = headers[:to].to_s.include?('ruby-dev') ? :ja : :en
        I18n.with_locale(locale) { super(headers) }
      end
    end
  end
end

Mailer.class_eval do
  prepend RedmineRubyLangMailingListCustomization::RedmineExt::Mailer
end
