module Migration
  class Issue < ActiveRecord::Base
    has_many :journals, :as => :journalized
    belongs_to :mailing_list
  end
  class Journal < ActiveRecord::Base
    belongs_to :journalized
    validates_presence_of :journalized
  end
  class MailingList < ActiveRecord::Base
    has_many :mailing_list_messages
  end
  class MailingListMessage < ActiveRecord::Base
    belongs_to :mailing_list
    belongs_to :issue
    belongs_to :journal
  
    validates_presence_of :mailing_list, :message_id
  end
  
  module_function
  def migrate
    Issue.transaction {
      count = Issue.count
      Issue.all(:order => 'id ASC').each_with_index do |issue, i|
        $stderr.puts "#{i}/#{count}"
        next if issue.mail_id.blank?
        MailingListMessage.create! :message_id => issue.mail_id,
          :mailing_list_id => issue.mailing_list_id,
          :mail_number => issue.mailing_list_code,
          :archive_url => issue.mailing_list.archive_url % issue.mailing_list_code,
          :issue_id => issue.id
  
        issue.journals.each do |j|
          next if j.mail_id.blank?
          MailingListMessage.create! :message_id => j.mail_id,
            :mailing_list_id => issue.mailing_list_id,
            :issue_id => issue.id, :journal_id => j.id,
            :references => issue.mail_id
        end
      end
    }
  
     <<-EOS.each_line {|l| l.strip!; next if l.empty?; p l; Issue.connection.execute(l) }
      ALTER TABLE issues DROP COLUMN mailing_list_id;
      ALTER TABLE issues DROP COLUMN mailing_list_code;
      ALTER TABLE issues DROP COLUMN mail_id;
      ALTER TABLE journals DROP COLUMN mail_id;
  
      ALTER TABLE mailing_list_trackings DROP COLUMN project_selector_pattern;
      ALTER TABLE mailing_list_trackings RENAME TO uses_of_mailing_list;
  
      ALTER TABLE mailing_lists CHANGE COLUMN name identifier varchar(255) NOT NULL;
      ALTER TABLE mailing_lists DROP COLUMN locale;
      ALTER TABLE mailing_lists ADD COLUMN driver_name varchar(255);
      ALTER TABLE mailing_lists CHANGE COLUMN archive_url driver_data;
      ALTER TABLE mailing_lists ADD COLUMN description text;
      UPDATE mailing_lists SET driver_name = "fml";
      ALTER TABLE mailing_lists CHANGE COLUMN driver_name driver_name varchar(255) NOT NULL;
  
      ALTER TABLE uses_of_mailing_list ADD COLUMN receptor_name varchar(255);
      UPDATE uses_of_mailing_list SET receptor_name = "default";
      ALTER TABLE uses_of_mailing_list CHANGE COLUMN receptor_name receptor_name varchar(255) NOT NULL;
    EOS
  end
end

Migration.migrate
