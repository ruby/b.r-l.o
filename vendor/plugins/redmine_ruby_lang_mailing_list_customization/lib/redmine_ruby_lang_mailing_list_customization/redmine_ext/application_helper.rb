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

    text.gsub(/\[([\w-]+):(\d+)\]/) do
      orig, name, number = $&, $1, $2.to_i
      ml = MailingList.find_by_identifier(name)
      if ml
        message = ml.messages.find_by_mail_number(number)
        if message
          link_to(orig, message.issue)
        else
          klass = ml.driver_class
          url = klass.archive_url_for(ml, number)
          url ? link_to(orig, url) : orig
        end
      else
        orig
      end
    end
  end
  alias_method_chain :textilizable, :ruby_lang_mailing_list_customization
end

