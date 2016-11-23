# See CVE-2013-0156
# https://groups.google.com/forum/?fromgroups=#!topic/rubyonrails-security/61bkgvnSGTQ
ActionController::Base.param_parsers.delete(Mime::XML)
