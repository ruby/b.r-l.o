class MailingListMessage < ActiveRecord::Base
  unloadable
  belongs_to :mailing_list
  belongs_to :issue
  belongs_to :journal
  validates_presence_of :mailing_list, :message_id

  def identifier
    if mail_number
      '[%s:%s]' % [mailing_list.identifier, mail_number]
    else
      '[%s:<unknown>]' % [mailing_list.identifier]
    end
  end
end
