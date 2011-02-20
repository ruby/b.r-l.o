module RedmineRubyLangMailingListCustomization
  class RubyCoreOrRubyDevReceptor
    def initialize(mailing_list)
      @mailing_list = mailing_list
    end

    (RedmineMailingListIntegration::Receptors::KNOWN_TYPES - %w[issue journal]).each do |type|
      define_method("#{type}_receive?") do |obj|
        false
      end
    end

    def issue_receive?(issue)
      if issue.lang == 'ja'
        return @mailing_list.identifier == 'ruby-dev'
      else
        return @mailing_list.identifier == 'ruby-core'
      end
    end

    def journal_receive?(journal)
      ml = journal.issue.mailing_list_message.mailing_list
      return ml == @mailing_list
    end
  end
end
