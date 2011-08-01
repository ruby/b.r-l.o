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
      return "" unless /\S/m =~ @text

      src = @text.split(/^/)
      unless /\A\s*^=begin/m =~ @text
        if Setting.plugin_redmine_rd_formatter[:rd_formatter_require_block]
          text = @text.gsub(/&/, '&amp;')
          text.gsub!(/</, '&lt;')
          #text.gsub!(/\[ruby-(?:dev|core|list|talk):\d+\]/, '<a href="http://www.rubyist.net/~eban/goto/\&')
          return "<div style=\"padding:1%;border:solid 1px #eee;white-space:pre-wrap;margin-left:5%;background-color:#eef\">#{text}</div>"
        else
          src.unshift("=begin\n").push("=end\n")
        end
      end

      include_path = [RD::RDTree.tmp_dir]
      tree = RD::RDTree.new(src, include_path, nil)
      FILTERS.each do |part_name, filter|
        tree.filter[part_name] = filter
      end
  
      # parse
      tree.parse
      visitor = RestrictedHTMLVisitor.new
      visitor.charcode = "utf8"
      visitor.visit(tree)
    rescue RuntimeError => e
      if e.message == "[BUG]: probably Parser Error while cutting off.\n"
        return "<pre>#{e.message}</pre>"
      else
        raise e
      end
    rescue Racc::ParseError => e
      return "<pre>#{e.message}</pre>"
    end
  end
end
