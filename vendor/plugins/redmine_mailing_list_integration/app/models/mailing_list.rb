class MailingList < ActiveRecord::Base
  has_many :uses_of_mailing_list, :class_name => 'UseOfMailingList'
  has_many :projects, :through => :uses_of_mailing_list

  has_many :messages, :class_name => 'MailingListMessage'

  validates_presence_of :identifier, :address, :driver_name
  validates_uniqueness_of :identifier

  def driver_for(email)
    driver_class.new(email, self)
  end

  def driver_class
    @driver_class ||= RedmineMailingListIntegration::Drivers.driver_for(driver_name)
  end
end
