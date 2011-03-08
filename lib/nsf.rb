require 'nsf/standard_extensions'

module Nsf
  class Document
    attr_accessor :nodes
    
    def initialize(nodes)
      @nodes = nodes
    end

    def title
      title_node = nodes.detect { |n| n.is_a?(Heading) && n.level == 1 }
      (title_node && title_node.text.present?) ? title_node.text : nil
    end

    def self.from(text, format)
      self.send("from_#{format}", text)
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
  end
     
  class Paragraph
    attr_accessor :text

    def initialize(text)
      @text = text
    end
  end

  class Fixedblock < Paragraph
  end

  class Heading
    attr_accessor :text, :level

    def initialize(text)
      text =~ /^(#+) (.*?)$/
      @text = $2
      @level = $1.length
    end
  end
end

require 'nsf/formats/nsf'
require 'nsf/formats/text'
require 'nsf/formats/html' #HTML depends on text support