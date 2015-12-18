#!/var/lib/redmine/current/script/runner
# note that you can add commit from Web UI
# https://bugs.ruby-lang.org/projects/ruby-trunk/repository/revisions/<revision>
rev = ARGV[1][/\A\d+\z/]
iid = ARGV[2][/\A\d+\z/]
c = Changeset.find_by_revision rev.to_i
a = c.issues
i = Issue.find iid
a << i
a.uniq!
c.issues = a
p c.issues
