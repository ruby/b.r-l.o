require 'iconv'
MailHandler.class_eval do
  def dispatch_with_ruby_lang_mailing_list_customization
    if charset = email.header.charset and charset.downcase != 'utf-8'
      email.body = Iconv.conv("UTF-8", charset, email.body) rescue nil
      email.subject = Iconv.conv("UTF-8", charset, email.subject) rescue nil
    end
    email.subject = email.subject.sub(/\[#{Regexp.escape driver.mailing_list.identifier}:\d+\]/, '')
    if subject_tag_re =~ email.subject
      email.subject = email.subject.sub(subject_tag_re, '')
      if %w[ ruby-core ruby-dev ].include? driver.mailing_list.identifier
        tracker_name, proj_name = $1, $2
        @ruby_lang_tracker_name = Tracker.find(:first, :conditions => ['LOWER(trackers.name) = LOWER(?)', tracker_name]).try(:name)
        @ruby_lang_project_name = 
          case proj_name
          when 'trunk' then 'ruby-trunk'
          when /\A1\.([89])\z/     then "ruby-1#{$1}"
          when /\A1\.8\.([6-9])\z/ then "ruby-18#{$1}"
          when /\A1\.9\.([1-9])\z/ then "ruby-19#{$1}"
          when /\A2\.0\.([0-9])\z/ then "ruby-20#{$1}"
          when /\A2\.1\.([0-9])\z/ then "ruby-21"
          else 'ruby'
          end
      end
    end
    dispatch_without_ruby_lang_mailing_list_customization
  end
  alias_method_chain :dispatch, :ruby_lang_mailing_list_customization

  unless instance_methods.grep('dispatch_to_chicken_and_egg')
    raise "mailing_list_integration plugin must have defined MailHandler#dispatch_to_chicken_and_egg"
  end
  def dispatch_to_chicken_and_egg
    # TODO queue
    false
  end

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
      text[/ruby \d\.\d\.\d(?:p\d+) (\d{4}-\d{1,2}-\d{1,2} (?:revision|patchlevel|trunk) \d+) \[/] || '-'
    end
  end
  alias_method_chain :extract_keyword!, :ruby_lang_mailing_list_customization

  private
  def subject_tag_re
    trackers = Tracker.all.map{|t| Regexp.escape(t.name) }.join('|')
    /\[(#{trackers})(?::([^\]]+))?\]/i
  end
end
