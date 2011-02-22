MailHandler.class_eval do
  def dispatch_with_ruby_lang_mailing_list_customization
    email.subject.sub(/\[#{Regexp.escape driver.mailing_list.identifier}:\d+\]/, '')
    if email.subject[subject_tag_re] &&= ''
      if %w[ ruby-core ruby-dev ].include? driver.mailing_list.identifier
        @ruby_lang_tracker_name, proj_name = $1, $2
        @ruby_lang_project_name = 
          case proj_name
          when 'trunk' then 'ruby-19'
          when /\A1\.([89])\z/     then "ruby-1#{$1}"
          when /\A1\.8\.([6-9])\z/ then "ruby-18#{$1}"
          when /\A1\.9\.([1-9])\z/ then "ruby-19#{$1}"
          else 'ruby'
          end
      end
    end
    dispatch_without_ruby_lang_mailing_list_customization
  end
  alias_method_chain :dispatch, :ruby_lang_mailing_list_customization

  def cleaned_up_text_body_with_ruby_lang_mailing_list_customization
    text = cleaned_up_text_body_without_ruby_lang_mailing_list_customization
    text.gsub(/^/, ' ')
  end
  alias_method_chain :cleaned_up_text_body, :ruby_lang_mailing_list_customization

  def extract_keyword_with_ruby_lang_mailing_list_customization!(text, attr, format=nil)
    value = extract_keyword_without_ruby_lang_mailing_list_customization!(text, attr, format)
    return value if value

    case attr
    when :tracker
      @ruby_lang_tracker_name
    when :project
      @ruby_lang_project_name
    when 'ruby -v'
      text[/ruby 1\.\d\.\d(?:p\d+) (\d{4}-\d{1,2}-\d{1,2} (?:revision|patchlevel|trunk) \d+) \[/] || '-'
    end
  end
  alias_method_chain :extract_keyword!, :ruby_lang_mailing_list_customization

  private
  def subject_tag_re
    trackers = Tracker.all.map{|t| Regexp.escape(t.name) }.join('|')
    /\[(#{trackers})(?::([^\]]+))?\]/i
  end
end
