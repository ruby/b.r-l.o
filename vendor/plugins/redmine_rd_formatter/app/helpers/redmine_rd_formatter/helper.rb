module RedmineRDFormatter
  module Helper
    unloadable

    def wikitoolbar_for(field_id)
      file = Engines::RailsExtensions::AssetHelpers.plugin_asset_path('redmine_rd_formatter', 'help', 'rd_syntax.html')
      help_link = l(:setting_text_formatting) + ': ' +
      link_to(l(:label_help), file,
              :onclick => "window.open(\"#{file}\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")

      javascript_include_tag('jstoolbar/jstoolbar') +
        javascript_include_tag('rd', :plugin => 'redmine_rd_formatter') +
        javascript_include_tag("lang/rd-#{current_language}", :plugin => 'redmine_rd_formatter') +
        javascript_tag(<<-EOS + (Setting.plugin_redmine_rd_formatter[:rd_formatter_require_block].to_s == 'true' ? <<-EOT : ''))
          var editor = $('#{field_id}');
          var toolbar = new jsToolBar($('#{field_id}'));
          toolbar.setHelpLink('#{help_link}');
          toolbar.draw();
        EOS
          var toggler = document.createElement('div');
          toggler.className = 'jsToggler';
          var toggleButton = document.createElement('button');
          toggleButton.setAttribute('type', 'button');
          toggleButton.className = 'jsToggleButton jst_disabled';
          toggleButton.title = 'RD';
          toggleButton.innerHTML = '<s>RD</s>';
          toggler.appendChild(toggleButton);

          var toolbarElement = $A(editor.parentNode.parentNode.childNodes).find(function(x){ return x.className == 'jstElements'});
          toolbarElement.parentNode.insertBefore(toggler, toolbarElement);
          Element.hide(toolbarElement);

          handler = function(){
            Element.toggle(toolbarElement);

            var src = editor.value
            if (toggleButton.className.split(' ').include('jst_disabled')) {
              toggleButton.className = 'jsToggleButton jst_enabled';
              toggleButton.innerHTML = '<b>RD</b>';
              if (!/^\\s*=begin/.test(src)) {
                src = "=begin\\n" + src;
                if (src[src.length - 1] != "\\n") src += "\\n";
                src += "=end\\n";
                editor.value = src;
              }
            } else {
              toggleButton.className = 'jsToggleButton jst_disabled';
              toggleButton.innerHTML = '<s>RD</s>';
              editor.value = src.replace(/^\\s*=begin\\n/, '').replace(/=end\\n\\s*$/, '');
            }
          };
          Event.observe(toggleButton, 'click', handler);
        EOT
    end

    def initial_page_content(page)
      "=begin\n= #{page.pretty_title}\n=end\n"
    end

    def heads_for_wiki_formatter
      stylesheet_link_tag('jstoolbar') +
        stylesheet_link_tag('rd', :plugin => 'redmine_rd_formatter')
    end
  end
end
