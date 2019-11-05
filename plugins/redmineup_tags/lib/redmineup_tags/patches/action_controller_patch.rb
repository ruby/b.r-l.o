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

module RedmineupTags
  module Patches
    module ActionControllerPatch
      def self.included(base)
        base.extend(ClassMethods) if Rails::VERSION::MAJOR < 4

        base.class_eval do
        end
      end

      module ClassMethods
        def before_action(*filters, &block)
          before_filter(*filters, &block)
        end

        def after_action(*filters, &block)
          after_filter(*filters, &block)
        end

        def skip_before_action(*filters)
          skip_before_filter(*filters)
        end
      end
    end
  end
end

unless ActionController::Base.included_modules.include?(RedmineupTags::Patches::ActionControllerPatch)
  ActionController::Base.send(:include, RedmineupTags::Patches::ActionControllerPatch)
end
