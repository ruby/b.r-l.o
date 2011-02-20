require 'project'
module RedmineMailingListIntegration
  module RedmineExt
    module ProjectExt
      def self.included(klass)
        klass.class_eval do
          has_many :uses_of_mailing_list, :class_name => 'UseOfMailingList'
          has_many :mailing_lists, :through => :'uses_of_mailing_list'
        end
      end

      Receptors::KNOWN_TYPES.each do |type|
        define_method("mail_routes_for_#{type}") do |obj|
          uses_of_mailing_list.select {|use| 
            use.send("#{type}_receive?", obj)
          }.map{|use|
            use.mailing_list
          }.uniq
        end
      end
    end
  end
end
Project.class_eval do
  include RedmineMailingListIntegration::RedmineExt::ProjectExt
end
