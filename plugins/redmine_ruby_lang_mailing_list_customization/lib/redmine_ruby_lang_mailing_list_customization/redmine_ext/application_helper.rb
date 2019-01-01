module RubyLangMailingListCustomizationApplicationHelper
  def textilizable(*args)
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
    text = super(*args)

    text.gsub(/\[([\w-]+):(\d+)\]/) do
      orig, name, number = $&, $1, $2.to_i
      ml = MailingList.find_by(identifier: name)
      if ml
        message = ml.messages.find_by(mail_number: number)
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
    end.html_safe
  end
end

ApplicationHelper.prepend RubyLangMailingListCustomizationApplicationHelper
