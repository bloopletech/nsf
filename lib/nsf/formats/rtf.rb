require 'rtf'

module Nsf
  class Document
    def to_rtf
      doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, 'Times New Roman'))
      nodes.each do |node|
        doc.paragraph << node.to_rtf
      end
      doc.to_rtf
    end
  end
     
  class Paragraph
    def to_rtf
      @text
    end
  end

  class Fixedblock < Paragraph
    def to_rtf
      @text
    end
  end

  class Heading
    def to_rtf
      @text
    end
  end
end