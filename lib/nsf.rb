require 'cgi'
require 'nokogiri'

require 'nsf/standard_extensions'

module Nsf
  class Document
    attr_accessor :nodes
    
    def initialize(nodes)
      @nodes = nodes
    end

    def self.from(text, format)
      self.send("from_#{format}", text)
    end

    def self.from_nsf(text)
      self.from_blocks(text.split("\n\n"))
    end

    def self.from_text(text)
      blocks = []

      in_paragraph = true
      current_text = ""
      prev_line = ""
      lines = text.split("\n")
      lines.each do |line|
        if line.blank? || line == lines.last || (current_text.present? && ((lsp(line) < lsp(prev_line))))
          if in_paragraph
            in_paragraph = false

            if current_text != ""
              blocks << current_text.gsub(/\s+/, ' ').strip
              current_text = ""
            end
          end
        elsif line =~ /^#+ /
          blocks << line
        else
          in_paragraph = true
          current_text << " " << line
          prev_line = line
        end
      end

      self.from_blocks(blocks)
    end

    #These tags should be recursively replaced by their contents and the resulting content appended to the current paragraph
    CONFORMING_TEXT_TAGS = %w(a abbr b bdi bdo cite code command datalist del dfn em i img ins kbd label mark math meter noscript output q ruby s samp small span strong sub sup textarea time var wbr)
    NONCONFORMING_TEXT_TAGS = %w(acronym big center dir font listing plaintext spacer strike tt u xmp)
    TEXT_TAGS = CONFORMING_TEXT_TAGS + NONCONFORMING_TEXT_TAGS

    HEADING_TAGS = %w(h1 h2 h3 h4 h5 h6)

    BLOCK_PASSTHROUGH_TAGS = %w(div form table tbody thead tfoot tr)

    BLOCK_INITIATING_TAGS = %w(article aside body header nav p pre section td th)

    def self.from_html(text)
      iterate = lambda do |nodes, blocks, current_text|
        just_appended_br = false
        nodes.map do |node|
          if node.text?
            current_text << " " << node.inner_text
            next
          end

          if node.node_name.downcase == 'head'
            next
          end

          #Handle repeated brs by making a paragraph break
          if node.node_name.downcase == 'br'
            if just_appended_br
              paragraph_text = current_text.gsub(/\s+/, ' ').strip
              blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
              current_text.replace("")
            else
              just_appended_br = true
            end
            next
          end

          #Pretend that the children of this node were siblings of this node (move them one level up the tree)
          if (TEXT_TAGS + BLOCK_PASSTHROUGH_TAGS).include?(node.node_name.downcase)
            iterate.call(node.children, blocks, current_text)
            next
          end

          #These tags terminate the current paragraph, if present, and start a new paragraph
          if BLOCK_INITIATING_TAGS.include?(node.node_name.downcase)
            paragraph_text = current_text.gsub(/\s+/, ' ').strip
            blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
            current_text.replace("")

            iterate.call(node.children, blocks, current_text)
            next
          end
        end
      end

      doc = Nokogiri::HTML(text)

      blocks = []
      current_text = ""

      iterate.call(doc.root.children, blocks, current_text)

      #Handle last paragraph of text
      paragraph_text = current_text.gsub(/\s+/, ' ').strip
      blocks << Paragraph.new(paragraph_text) if paragraph_text.present?
      
      Document.new(blocks)
    end

    def self.from_blocks(blocks)
      self.new(blocks.map do |block|
        if block =~ /^#+ /
          Heading.new(block)
        elsif block =~ /^    /
          Fixedblock.from_nsf(block)
        else
          Paragraph.new(block)
        end
      end)
    end
  
    # LSP == Leading SPaces
    def self.lsp(str)
      str =~ /^(\s+)/
      $1 ? $1.length : 0
    end

    def to_nsf
      nodes.map(&:to_nsf).join("\n\n")
    end

    def to_html
      nodes.map(&:to_html).join
    end
  end
     
  class Paragraph
    attr_accessor :text

    def initialize(text)
      @text = text
    end

    def to_nsf
      word_wrap(@text, 80)
    end

    def to_html
      #in_bold = false
      #in_italic = false

      out = @text
      #out = out.gsub(/(\A\*| \*)(.*?)(\*\Z|\* )/, "<b>\\2</b>") #Need to rethink
      
      "<p>#{out}</p>"
    end

    private
    #Sourced from ActionView::Helpers::TextHelper#word_wrap
    def word_wrap(text, line_width)
      text.split("\n").collect do |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
      end * "\n"
    end
  end

  class Fixedblock < Paragraph
    
    def to_html
      "<pre>#{CGI.escapeHTML(text.gsub(/^    /, ''))}</pre>"
    end
  end

  class Heading
    attr_accessor :text, :level

    def initialize(text)
      text =~ /^(#+) (.*?)$/
      @text = $2
      @level = $1.length
    end

    def to_nsf
      "#{"#" * level} #{text}"
    end
    
    def to_html
      "<h#{level}>#{CGI.escapeHTML(text)}</h#{level}>"
    end
  end
end