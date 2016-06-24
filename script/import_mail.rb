#!/var/lib/redmine/current/script/runner
/((ruby-(?:core|dev)):\d+)/ =~ ARGV.last
mid = $1
ml = $2
p mid
abort "no ML id given" unless mid
Rails.logger.level=0

=begin
h = {}
MailingList.find_by_identifier(ml).messages.map(&:mail_number).each do |n|
  h[n] = true
end
(36932..44999).each do |n|
next if h[n]
mid = ml+":"+n.to_s
=end
m = RedmineMailingListIntegrationIMAPSupplement::IMAP.fetch(ml, ['SUBJECT', mid])
#next unless m && m[0]
p MailHandler.receive(m[0].attr["RFC822"], :unknown_user=>"accept", :no_permission_check=>'1')
#end
Rails.logger.flush
