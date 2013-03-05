module Nsf
  class Document
    def self.from_nsf(text)
      self.from_blocks(text.split("\n\n"))
    end

    def to_nsf
      nodes.map(&:to_nsf).join("\n\n")
    end
  end
     
  class Paragraph
    def to_nsf
      @text
#      word_wrap(@text, 80)
    end

    private
    #Sourced from ActionView::Helpers::TextHelper#word_wrap
    def word_wrap(text, line_width)
      o = text.split("\n").collect do |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})([[:space:]]+|$)/, "\\1\n").strip : line
      end * "\n"
    end
  end

  class Fixedblock < Paragraph
  end

  class Heading
    def to_nsf
      "#{"#" * level} #{text}"
    end
  end
end
