class MailToIssue
  private
  def save; end
  def save!; end
  def new_record?; true end
  def update_attribute; end
  def self.human_attribute_name(name)
    ActiveRecord::Base.human_attribute_name(name)
  end
  def self.human_name(options = {})
    "mail to issue"
  end

  public
  include ActiveModel::Validations
  def self.self_and_descendants_from_active_record; [self] end

  ATTRIBUTES = %w[
    mailing_list_id
    mail_number
    tracker_id
  ]
  attr_accessor *ATTRIBUTES
  validates_presence_of *ATTRIBUTES

  def initialize(hash = nil)
    return if hash.blank?
    hash.each do |name, value|
      if ATTRIBUTES.include?(name.to_s)
        self.send("#{name}=", value)
      end
    end
  end

  def mailing_list
    mailing_list_id and MailingList.find(mailing_list_id)
  end
  def tracker
    tracker_id and Tracker.find(tracker_id)
  end

end
