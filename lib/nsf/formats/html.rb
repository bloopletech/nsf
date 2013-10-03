#HTML depends on text support

require 'cgi'
require 'nokogiri'

module Nsf
  class Document
    #These tags should be recursively replaced by their contents and the resulting content appended to the current paragraph
    CONFORMING_TEXT_TAGS = %w(a abbr b bdi bdo cite code command datalist del dfn em i img ins kbd label mark math meter noscript output q ruby s samp small span strong sub sup textarea time var wbr)
    NONCONFORMING_TEXT_TAGS = %w(acronym big center dir font listing plaintext spacer strike tt u xmp)
    TEXT_TAGS = CONFORMING_TEXT_TAGS + NONCONFORMING_TEXT_TAGS

    HEADING_TAGS = %w(h1 h2 h3 h4 h5 h6)

    BLOCK_PASSTHROUGH_TAGS = %w(div dl form ol table tbody thead tfoot tr ul)

    BLOCK_INITIATING_TAGS = %w(article aside body blockquote dd dt header li nav p pre section td th ul)

    BLOCK_PLAIN_TEXT_TAGS = %w(pre plaintext listing xmp)
    
    ENHANCERS = { %w(b strong) => "*", %(i em) => "_" }

    def self.from_html(text)
      iterate = lambda do |node, blocks, current_text|
        just_appended_br = false
        node_name = node.node_name.downcase
        #puts "node_name: #{node_name}, current_text: #{current_text}"

        return if node.attributes.key?("data-nsf-ignore") && node.attributes["data-nsf-ignore"].value == "true"

        return if node_name == 'head'

        if node.text?
          text = node.inner_text
          current_text << text
          return
        end

        #Handle repeated brs by making a paragraph break
        if node_name == 'br'
          if just_appended_br
            paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
            blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
            current_text.replace("")
          else
            just_appended_br = true
          end
          return
        end

        #These tags terminate the current paragraph, if present, and start a new paragraph
        if BLOCK_INITIATING_TAGS.include?(node_name)
          #puts "initiated"
          node.children.each { |n| iterate.call(n, blocks, current_text) }

          paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
          blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
          current_text.replace("")
            

#          if BLOCK_PLAIN_TEXT_TAGS.include?(node_name)
#            blocks.concat(Nsf::Document.from_text(current_text).nodes)
#            current_text.replace("")
#          end

          return
        end
        
        if ENHANCERS.keys.flatten.include?(node_name)
          ENHANCERS.each_pair do |tags, nsf_rep|
            if tags.include?(node_name)
              new_text = ""
              node.children.each { |n| iterate.call(n, blocks, new_text) }
              current_text << nsf_rep << new_text << nsf_rep
            end
          end
          return
        end
        
        #Pretend that the children of this node were siblings of this node (move them one level up the tree)
        if (TEXT_TAGS + BLOCK_PASSTHROUGH_TAGS).include?(node_name)
          node.children.each { |n| iterate.call(n, blocks, current_text) }
          return
        end

        if HEADING_TAGS.include?(node_name)
          node.children.each { |n| iterate.call(n, blocks, current_text) }

          heading_text = current_text.gsub(/[[:space:]]+/, ' ').strip
          blocks << Heading.new(heading_text, node_name[1..-1].to_i) if heading_text.present?
          current_text.replace("")
          return
        end

        node.children.each { |n| iterate.call(n, blocks, current_text) }
      end

      blocks = []

      doc = Nokogiri::HTML(text)

      iterate.call(doc.root, blocks, "")

      title_tag = doc.css("title").first
      if title_tag && !blocks.detect { |b| b.is_a?(Heading) && b.level == 1 }
        blocks.unshift(Heading.new(title_tag.inner_text, 1))
      end

      Document.new(blocks)
    end

    def to_html
      nodes.map(&:to_html).join
    end
  end
     
  class Paragraph
    def to_html_fragment(escape = true)
      out = (escape ? CGI.escapeHTML(@text) : @text).split(BOLD_ITALIC_REGEX)

      if ((out.select { |element| element == "*" }).length % 2 == 0) && ((out.select { |element| element == "_" }).length % 2 == 0)
        in_bold = false
        in_italic = false

        out.map! do |element|        
          if element == "*"
            in_bold = !in_bold
            in_bold ? "<b>" : "</b>" #Note that in_bold has been inverted, so this is inverted as well
          elsif element == "_"
            in_italic = !in_italic
            in_italic ? "<i>" : "</i>" #Note that in_italic has been inverted, so this is inverted as well
          else
            element
          end
        end
      end

      out.join
    end

    def to_html
      "<p>#{to_html_fragment}</p>"
    end
  end

  class Fixedblock < Paragraph
    def to_html
      "<pre>#{CGI.escapeHTML(text.gsub(/^    /, ''))}</pre>"
    end
  end

  class Heading
    def to_html
      "<h#{level} id=\"#{ref_html}\">#{CGI.escapeHTML(text)}</h#{level}>"
    end

    def ref_html
      "heading_#{level}_#{CGI.escapeHTML(text)}"
    end
  end
end
