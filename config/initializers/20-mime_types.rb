# Add new mime types for use in respond_to blocks:

Mime::SET << Mime::CSV unless Mime::SET.include?(Mime::CSV)
Mime::Type.register 'application/pdf', :pdf
Mime::Type.register 'image/png', :png
Mime::Type.register 'text/x-diff', :patch
Mime::Type.register 'text/x-diff', :diff
Mime::Type.register 'text/x-rb', :rb
