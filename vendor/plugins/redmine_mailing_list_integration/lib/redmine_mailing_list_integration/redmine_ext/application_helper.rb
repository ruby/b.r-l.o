ApplicationHelper.class_eval do
  def textilizable_with_mailing_list_integration(*args)
    text = textilizable_without_mailing_list_integration(*args)
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
  alias_method_chain :textilizable, :mailing_list_integration
end
