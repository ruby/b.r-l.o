# encoding: utf-8
#
# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def plugin_fixtures(*fixtures)
  fixtures_directory = "#{File.dirname(__FILE__)}/fixtures/"
  fixture_names =
    if fixtures.first == :all
      Dir["#{fixtures_directory}/**/*.{yml}"].map do |file_path|
        file_path[(fixtures_directory.size + 1)..-5]
      end
    else
      fixtures.flatten.map { |n| n.to_s }
    end

  if ActiveRecord::VERSION::MAJOR >= 4
    ActiveRecord::FixtureSet.create_fixtures fixtures_directory, fixture_names
  else
    ActiveRecord::Fixtures.create_fixtures fixtures_directory, fixture_names
  end
end

plugin_fixtures :all

def compatible_request(type, action, parameters = {})
  Rails.version < '5.1' ? send(type, action, parameters) : send(type, action, params: parameters)
end

def compatible_xhr_request(type, action, parameters = {})
  Rails.version < '5.1' ? xhr(type, action, parameters) : send(type, action, params: parameters, xhr: true)
end

# Returns the issues that are displayed in the list in the same order
def issues_in_list
  ids = css_select('tr.issue td.id').map{ |tag| tag['text'].to_i }
  Issue.where(id: ids).sort_by { |issue| ids.index(issue.id) }
end
