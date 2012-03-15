class MailingListMessage < ActiveRecord::Base
  unloadable
  belongs_to :mailing_list
  belongs_to :issue
  belongs_to :journal
  validates_presence_of :mailing_list

  def self.scan_identifier(str)
    ary = []
    str.scan(/\[([a-zA-Z\-_]):(\d+)\]/) do |mlname, num|
      ml = MailingList.find_by_identifier(mlname)
      m = ml.messages.find_by_mail_number(num)
      ary << m if m
    end
  end

  def self.find_by_identifier(mlref)
    if /\[([a-zA-Z\-_]):(\d+)\]/ =~ mlref
      ml = MailingList.find_by_identifier($1)
      ml.messages.find_by_mail_number($2)
    end
  end

  def identifier
    if mail_number
      '[%s:%s]' % [mailing_list.identifier, mail_number]
    else
      '[%s:<unknown>]' % [mailing_list.identifier]
    end
  end
end
