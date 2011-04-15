require 'nsf/standard_extensions'

module Nsf
  class Document
    attr_accessor :nodes
    
    def initialize(nodes)
      @nodes = nodes
    end

    def title
      title_node = nodes.detect { |n| n.is_a?(Heading) && n.level == 1 }
      if title_node && title_node.text.present?
        title_node.text
      elsif nodes.first && (nodes.first.text.length < 100)
        nodes.first.text
      else
        nil
      end
    end

    def self.from(text, format)
      self.send("from_#{format}", text)
    end

    def self.from_blocks(blocks)
      self.new(blocks.map do |block|
        if block =~ /^#+ /
          Heading.from_nsf(block)
        elsif block =~ /^    /
          Fixedblock.from_nsf(block)
        else
          Paragraph.from_nsf(block)
        end
      end)
    end
  end
     
  class Paragraph
    attr_reader :text

    BOLD_ITALIC_REGEX = /(?:(\W|^)(\*)|(\*)(\W|$)|(\W|^)(_)|(_)(\W|$))/

    def initialize(text)
      @text = text
    end

    def self.from_nsf(text)
      self.new(text.gsub(/[[:space:]]+/, ' ').strip)
    end
  end

  class Fixedblock < Paragraph
  end

  class Heading
    attr_reader :text, :level

    def initialize(text, level)
      @text = text
      @level = level
    end

    def self.from_nsf(text)
      text =~ /^(#+) (.*?)$/
      self.new($2, $1.length)  
    end
  end
end

require 'nsf/formats/nsf'
require 'nsf/formats/text'
require 'nsf/formats/html' #HTML depends on text support
require 'nsf/formats/rtf'