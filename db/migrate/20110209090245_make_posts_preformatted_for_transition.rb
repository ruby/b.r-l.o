class MakePostsPreformattedForTransition < ActiveRecord::Migration
  class Issue < ActiveRecord::Base; end
  class Journal < ActiveRecord::Base; end
  def self.up
    ActiveRecord::Base.transaction {
      Issue.all.each do |issue|
        issue.description = issue.description.gsub(/^/, ' ')
        issue.save!
      end
      Journal.all.each do |journal|
        journal.notes = journal.notes.gsub(/^/, ' ')
        journal.save!
      end
    }
  end

  def self.down
    ActiveRecord::Base.transaction {
      Journal.all.each do |journal|
        journal.notes = journal.notes.gsub(/^ /, '')
        journal.save!
      end
      Issue.all.each do |issue|
        issue.description = issue.description.gsub(/^ /, '')
        issue.save!
      end
    }
  end
end
