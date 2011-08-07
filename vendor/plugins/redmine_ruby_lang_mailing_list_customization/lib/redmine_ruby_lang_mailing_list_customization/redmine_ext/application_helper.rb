ApplicationHelper.class_eval do
  def textilizable_with_ruby_lang_mailing_list_customization(*args)
    if args.last.is_a?(Hash)
      options = args.last
    else
      options = {}
      args.push(options)
    end

    force_simple = case params[:controller].to_s
                   when 'issues', 'journals', 'projects', 'previews', 'welcome', 'wiki'
                     false
                   else
                     true
                   end
    options[:force_simple] = force_simple
    text = textilizable_without_ruby_lang_mailing_list_customization(*args)

    text.gsub(/\G([^<]*(?:<[^>]*>[^<]*)*)(\[([\w\-]+):(\d+)\])/) do
      orig, pre, ref, name, number = $&, $1, $2, $3, $4.to_i
      ml = MailingList.find_by_identifier(name)
      if ml
        message = ml.messages.find_by_mail_number(number)
        if message
          pre + link_to(ref, message.issue)
        else
          klass = ml.driver_class
          url = klass.archive_url_for(ml, number)
          pre + (url ? link_to(ref, url) : orig)
        end
      else
        orig
      end
    end
  end
  alias_method_chain :textilizable, :ruby_lang_mailing_list_customization
end

