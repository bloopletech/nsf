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

    BLOCK_PASSTHROUGH_TAGS = %w(div form table tbody thead tfoot tr)

    BLOCK_INITIATING_TAGS = %w(article aside body blockquote header nav p pre section td th)

    BLOCK_PLAIN_TEXT_TAGS = %w(pre plaintext listing xmp)
    
    ENHANCERS = { %w(b strong) => "*", %(i em) => "_" }

    def self.from_html(text)
      iterate = lambda do |nodes, blocks, current_text|
        just_appended_br = false
        nodes.map do |node|
          node_name = node.node_name.downcase
        
          if node.text?
            text = node.inner_text
            current_text << text
            just_opened_style = false
            next
          end
          
          if node_name == 'head'
            next
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
            next
          end
          
          if ENHANCERS.keys.flatten.include?(node_name)
            ENHANCERS.each_pair do |tags, nsf_rep|
              if tags.include?(node_name)
                new_text = ""
                iterate.call(node.children, blocks, new_text)
                current_text << nsf_rep << new_text << nsf_rep
              end
            end
            next
          end
          
          #Pretend that the children of this node were siblings of this node (move them one level up the tree)
          if (TEXT_TAGS + BLOCK_PASSTHROUGH_TAGS).include?(node_name)
            iterate.call(node.children, blocks, current_text)
            next
          end
          
          #These tags terminate the current paragraph, if present, and start a new paragraph
          if BLOCK_INITIATING_TAGS.include?(node_name)
            paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
            blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
            current_text.replace("")
            
            iterate.call(node.children, blocks, current_text)

            if BLOCK_PLAIN_TEXT_TAGS.include?(node_name)
              blocks += Nsf::Document.from_text(current_text).nodes
              current_text.replace("")
            end

            next
          end
        end
      end

      blocks = []

      doc = Nokogiri::HTML(text)

      title_tag = doc.css("title").first
      blocks << Heading.new("# #{title_tag.inner_text}") if title_tag
      
      current_text = ""

      iterate.call(doc.root.children, blocks, current_text)

      #Handle last paragraph of text
      paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
      blocks << Paragraph.new(paragraph_text) if paragraph_text.present?

      Document.new(blocks)
    end

    def to_html
      nodes.map(&:to_html).join
    end
  end
     
  class Paragraph
    def to_html
      #in_bold = false
      #in_italic = false

      out = @text
      #out = out.gsub(/(\A\*| \*)(.*?)(\*\Z|\* )/, "<b>\\2</b>") #Need to rethink
      
      "<p>#{out}</p>"
    end
  end

  class Fixedblock < Paragraph
    def to_html
      "<pre>#{CGI.escapeHTML(text.gsub(/^    /, ''))}</pre>"
    end
  end

  class Heading
    def to_html
      "<h#{level}>#{CGI.escapeHTML(text)}</h#{level}>"
    end
  end
end