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

module IssuesTagsHelper
  def sidebar_tags
    unless @sidebar_tags
      @sidebar_tags = []
      if RedmineupTags.settings['issues_sidebar'].to_sym != :none
        @sidebar_tags = Issue.available_tags(project: @project,
                                             open_only: (RedmineupTags.settings['issues_open_only'].to_i == 1))
      end
    end
    @sidebar_tags.to_a
  end

  def render_sidebar_tags
    render_tags_list(sidebar_tags, show_count: (RedmineupTags.settings['issues_show_count'].to_i == 1),
                                   open_only: (RedmineupTags.settings['issues_open_only'].to_i == 1),
                                   style: RedmineupTags.settings['issues_sidebar'].to_sym)
  end
end
