# PDF depends on HTML and text support

require 'prawn'

module Nsf
  class Document
    PDF_DEFAULT_FONT_SIZE = 10.5
    PDF_LEADING = 0.4
    def to_pdf(base_font_size = PDF_DEFAULT_FONT_SIZE)
      pdf = Prawn::Document.new(:page_size => "A4", :margin => (base_font_size * 2.22222).round)

      fd = "#{File.dirname(__FILE__)}/fonts"
      pdf.font_families.update("Open Sans" => {
        :normal => "#{fd}/OpenSans-Regular.ttf",
        :bold => "#{fd}/OpenSans-Bold.ttf",
        :italic => "#{fd}/OpenSans-Italic.ttf",
        :bold_italic => "#{fd}/OpenSans-BoldItalic.ttf"
      })
      pdf.font "Open Sans"
      pdf.font_size = base_font_size
      pdf.default_leading = (PDF_LEADING * base_font_size).round

      nodes.each { |n| n.to_pdf(pdf) }

      pdf.render
    end
  end

  class Paragraph
    PDF_PARAGRAPH_LEADING = 1.2
    def to_pdf(pdf)
      pdf.text to_html_fragment(false), :inline_format => true
      pdf.move_down (pdf.font_size * PDF_PARAGRAPH_LEADING).round
    end
  end

  class Heading
    PDF_FONT_RATIOS = [2.22222, 1.66666, 1.33333]
    PDF_HEADING_LEADING = 0.6
    def to_pdf(pdf)
      size = (PDF_FONT_RATIOS[level - 1] * pdf.font_size).round
      pdf.text text, :size => size, :leading => (size * Document::PDF_LEADING).round, :style => :bold
      pdf.move_down (size * PDF_HEADING_LEADING).round
    end
  end
end


