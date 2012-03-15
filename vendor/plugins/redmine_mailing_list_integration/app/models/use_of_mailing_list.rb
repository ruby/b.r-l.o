require 'forwardable'
class UseOfMailingList < ActiveRecord::Base
  extend Forwardable
  unloadable
  self.table_name = 'uses_of_mailing_list'
  belongs_to :mailing_list
  belongs_to :project
  validates_presence_of :mailing_list, :project, :receptor_name

  def receptor
    @receptor ||= begin
      klass = RedmineMailingListIntegration::Receptors.receptor_for(receptor_name)
      klass.new(mailing_list)
    end
  end
  def_delegators :receptor, *RedmineMailingListIntegration::Receptors::KNOWN_TYPES.map{|type| "#{type}_receive?" }

  def reload
    @driver_class = @receptor = nil
    super
  end
end
