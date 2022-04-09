# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2021 RedmineUP
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

if Redmine::Plugin.installed?(:redmine_agile) &&
   Gem::Version.new(Redmine::Plugin.find(:redmine_agile).version) >= Gem::Version.new('1.4.3') &&
   AGILE_VERSION_TYPE == 'PRO version'

  require_dependency 'query'

  module RedmineupTags
    module Patches
      module AgileVersionsQueryPatch
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.class_eval do
            unloadable
            add_available_column QueryTagsColumn.new(:tags_relations, caption: :tags)
          end
        end

        module InstanceMethods

        end
      end
    end
  end

  unless AgileVersionsQuery.included_modules.include?(RedmineupTags::Patches::AgileVersionsQueryPatch)
    AgileVersionsQuery.send(:include, RedmineupTags::Patches::AgileVersionsQueryPatch)
  end
end
