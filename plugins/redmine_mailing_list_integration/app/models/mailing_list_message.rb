class MailingListMessage < ActiveRecord::Base
  unloadable
  belongs_to :mailing_list
  belongs_to :issue
  belongs_to :journal

  validates_presence_of :mailing_list

  def identifier
    if mail_number && mailing_list
      '[%s:%s]' % [mailing_list.identifier, mail_number]
    elsif mailing_list
      '[%s:<unknown>]' % [mailing_list.identifier]
    else
      '[<unknown>:<unknown>]'
    end
  end
end
