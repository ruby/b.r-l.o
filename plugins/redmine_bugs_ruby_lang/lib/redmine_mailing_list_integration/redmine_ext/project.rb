module RedmineMailingListIntegration
  module RedmineExt
    module Project
      def self.included(klass)
        klass.class_eval do
          has_many :uses_of_mailing_list, class_name: 'UseOfMailingList'
          has_many :mailing_lists, through: :uses_of_mailing_list
        end
      end

      Receptors::KNOWN_TYPES.each do |type|
        define_method("mail_routes_for_#{type}") do |obj|
          uses_of_mailing_list.select do |use|
            use.send("#{type}_receive?", obj)
          end.map do |use|
            use.mailing_list
          end.uniq
        end
      end
    end
  end
end
Project.class_eval do
  include RedmineMailingListIntegration::RedmineExt::Project
end
