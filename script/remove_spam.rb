#!/var/lib/redmine/current/script/runner
User.transaction do
  Issue.find_each(:include=>:author,:conditions=>'users.status=3'){|x|x.destroy}
  Journal.find_each(:include=>:user,:conditions=>'users.status=3'){|x|x.destroy}
  Comment.find_each(:include=>:author,:conditions=>'users.status=3'){|x|x.destroy}
end
