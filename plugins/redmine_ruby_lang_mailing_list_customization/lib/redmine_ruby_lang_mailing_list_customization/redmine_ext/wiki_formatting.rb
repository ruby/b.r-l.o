Redmine::WikiFormatting.module_eval do
  class << self
    def to_html_with_ruby_lang_mailing_list_customization(format, text, options = {}, &block)
      format = nil if options[:force_simple]
      to_html_without_ruby_lang_mailing_list_customization(format, text, options = {}, &block)
    end

    alias_method_chain :to_html, :ruby_lang_mailing_list_customization
  end
end
