module RubyLangMailingListCustomizationWikiFormatting
  class << self
    def to_html(format, text, options = {}, &block)
      format = nil if options[:force_simple]
      super(format, text, options = {}, &block)
    end
  end
end

Redmine::WikiFormatting.prepend RubyLangMailingListCustomizationWikiFormatting
