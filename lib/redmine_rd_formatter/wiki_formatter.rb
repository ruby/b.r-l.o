require 'rd/rdfmt'
require 'rd/visitor'
require 'rd/version'
require 'rd/rd2html-lib'

module RedmineRDFormatter
  class WikiFormatter
    FILTERS = [
    ].freeze

    class RestrictedHTMLVisitor < RD::RD2HTMLVisitor
      def apply_to_DocumentElement(element, content)
        content.join
      end
    end

    def initialize(text)
      @text = text
    end
    def to_html(&block)
      visitor = RestrictedHTMLVisitor.new
      src = @text.split(/^/)
      if src.find{|i| /\S/ === i } and !src.find{|i| /^=begin\b/ === i }
        src.unshift("=begin\n").push("=end\n")
      end

      include_path = [RD::RDTree.tmp_dir]
      tree = RD::RDTree.new(src, include_path, nil)
      FILTERS.each do |part_name, filter|
        tree.filter[part_name] = filter
      end
  
      # parse
      tree.parse
      visitor.charcode = "utf8"
      visitor.visit(tree)
    rescue Racc::ParseError => e
      return "<pre>#{e.message}</pre>"
    end
  end
end
