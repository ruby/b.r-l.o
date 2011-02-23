module RedmineRubyLangMailingListCustomization
  class RubyCoreOrRubyDevReceptor
    def initialize(mailing_list)
      @mailing_list = mailing_list
    end

    (RedmineMailingListIntegration::Receptors::KNOWN_TYPES - %w[issue]).each do |type|
      define_method("#{type}_receive?") do |obj|
        false
      end
    end

    def issue_receive?(issue)
      if issue.mailing_list_message
        ml = issue.mailing_list_message.mailing_list
        return ml == @mailing_list
      else
        if issue.lang == 'ja'
          return @mailing_list.identifier == 'ruby-dev'
        else
          return @mailing_list.identifier == 'ruby-core'
        end
      end
    end
  end
end
