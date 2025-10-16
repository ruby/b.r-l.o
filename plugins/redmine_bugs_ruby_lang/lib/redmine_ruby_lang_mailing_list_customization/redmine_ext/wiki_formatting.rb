module RedmineRubyLangMailingListCustomization
  module RedmineExt
    module WikiFormatting
      class << self
        def to_html(format, text, options = {}, &block)
          format = nil if options[:force_simple]
          super(format, text, options = {}, &block)
        end
      end
    end
  end
end

Redmine::WikiFormatting.class_eval do
  prepend RedmineRubyLangMailingListCustomization::RedmineExt::WikiFormatting
end
