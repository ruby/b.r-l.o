require 'open-uri'

module RedmicaS3
  module PdfPatch
    extend ActiveSupport::Concern

    included do
      prepend PrependMethods
    end

    class_methods do
    end

    module PrependMethods
      def self.prepended(base)
        class << base
          self.prepend(ClassMethods)
        end
      end

      module ClassMethods
      end

      def get_image_filename(attrname)
        atta = Redmine::Export::PDF::RDMPdfEncoding.attach(@attachments, attrname, 'UTF-8')
        if atta
          atta
        elsif %r{/attachments/download/(?<id>[^/]+)/} =~ attrname and
              atta = @attachments.find{|a| a.id.to_s == id} and
              atta.readable? and atta.visible?
          atta
        elsif %r{/attachments/thumbnail/(?<id>[^/]+)/(?<size>\d+)} =~ attrname and
              atta = @attachments.find{|a| a.id.to_s == id} and
              atta.readable? and atta.visible?
          atta.thumbnail(size: size)
        else
          nil
        end
      end

      protected

      def openHTMLTagHandler(dom, key, cell)
        tag = dom[key]
        unless tag['value'] == 'img'
          return super
        end

        if !tag['attribute']['src'].nil?
          tag['attribute']['src'].gsub!(/%([0-9a-fA-F]{2})/){$1.hex.chr}

          img_name = tag['attribute']['src']
          tag['attribute']['src'] = get_image_filename(img_name)

          tag['width'] ||= 0
          tag['height'] ||= 0
          tag['attribute']['align'] = 'bottom'
          align = 'B'

          prevy = @y
          xpos = @x
          xpos +=
            # eliminate marker spaces
            if !dom[key - 1].nil?
              if (dom[key - 1]['value'] == ' ') or !dom[key - 1]['trimmed_space'].nil?
                -GetStringWidth(32.chr)
              elsif @rtl and (dom[key - 1]['value'] == '  ')
                2 * GetStringWidth(32.chr)
              else
                0
              end
            else
              0
            end

          imglink = ''
          if !@href['url'].nil? and !empty_string(@href['url'])
            imglink = @href['url']
            if imglink[0, 1] == '#'
              # convert url to internal link
              page = imglink.sub(/^#/, "").to_i
              imglink = AddLink()
              SetLink(imglink, 0, page)
            end
          end
          border =
            if !tag['attribute']['border'].nil? and !tag['attribute']['border'].empty?
              # currently only support 1 (frame) or a combination of 'LTRB'
              case tag['attribute']['border']
              when '0'
                0
              when '1'
                1
              else
                tag['attribute']['border']
              end
            else
              0
            end

          iw = tag['width'] ? getHTMLUnitToUnits(tag['width'], 1, 'px', false) : 0
          ih = tag['height'] ? getHTMLUnitToUnits(tag['height'], 1, 'px', false) : 0

          # store original margin values
          l_margin = @l_margin
          r_margin = @r_margin

          SetLeftMargin(@l_margin + @c_margin)
          SetRightMargin(@r_margin + @c_margin)

          result_img =
            proc_image_file(tag['attribute']['src']) do |img_file|
              Image(img_file, xpos, @y, iw, ih, '', imglink, align, false, 300, '', false, false, border, false, false, true)
            end

          @y =
            if result_img or ih != 0
              case align
              when 'T'
                prevy
              when 'M'
                (@img_rb_y + prevy - (tag['fontsize'] / @k)) / 2
              when 'B'
                @img_rb_y - (tag['fontsize'] / @k)
              else
                prevy
              end
            else
              prevy
            end

          # restore original margin values
          SetLeftMargin(l_margin)
          SetRightMargin(r_margin)

          if result_img == false && !img_name.nil?
            Write(@lasth, File::basename(img_name) + ' ', '', false, '', false, 0, false)
          end
        end

        if dom[key]['self'] and dom[key]['attribute']['pagebreakafter']
          pba = dom[key]['attribute']['pagebreakafter']
          # check for pagebreak
          if (pba == 'true') or (pba == 'left') or (pba == 'right')
            # add a page (or trig AcceptPageBreak() for multicolumn mode)
            checkPageBreak(@page_break_trigger + 1)
          end
          if ((pba == 'left') and ((!@rtl and (@page % 2 == 0)) or (@rtl and (@page % 2 != 0)))) or ((pba == 'right') and ((!@rtl and (@page % 2 != 0)) or (@rtl and (@page % 2 == 0))))
            # add a page (or trig AcceptPageBreak() for multicolumn mode)
            checkPageBreak(@page_break_trigger + 1)
          end
        end
        dom
      end

    end

    def get_image_file(image_uri)
      #use a temporary file....
      tmpFile = Tempfile.new(['tmp_', '.img'], self.class.k_path_cache)
      tmpFile.binmode
      if image_uri.is_a?(Attachment)
        tmpFile.write(image_uri.raw_data)
      elsif image_uri.is_a?(Array)  # thumbnail
        tmpFile.write(image_uri.last)
      else
        open(image_uri, 'rb') do |read_file|
          tmpFile.write(read_file.read)
        end
      end
      tmpFile.fsync
      tmpFile
    end

    private

    def proc_image_file(src, &block)
      tmpFile = nil
      img_file =
        if src.is_a?(Attachment) || src.is_a?(Array) || /^http/.match?(src)
          tmpFile = get_image_file(src)
          tmpFile.path
        else
          src
        end
      yield img_file
    rescue => err
      logger.error "pdf: Image: error: #{err.message}"
      false
    ensure
      # remove temp files
      tmpFile.close(true) if tmpFile
    end
  end
end
