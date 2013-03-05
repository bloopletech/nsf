# PDF depends on HTML and text support

require 'prawn'

module Nsf
  class Document
    def self.pdf_pt(px)
      #Assumes screen has true dpi of 96
      (px * (1 / 96.0)) / (1 / 72.0)
    end

    PDF_MARGINS = pdf_pt(40)
    PDF_FONT_SIZE = pdf_pt(18)
    PDF_LEADING = 0.4
    def to_pdf
      pdf = Prawn::Document.new(:page_size => "A4", :margin => PDF_MARGINS)
      pdf.font_families.update("Open Sans" => {
        :normal => "#{File.dirname(__FILE__)}/fonts/OpenSans-Regular.ttf",
        :bold => "#{File.dirname(__FILE__)}/fonts/OpenSans-Bold.ttf"
      })
      pdf.font "Open Sans"
      pdf.font_size = PDF_FONT_SIZE
      pdf.default_leading = PDF_LEADING * PDF_FONT_SIZE

      nodes.each { |n| n.to_pdf(pdf) }

      pdf.render
    end
  end

  class Paragraph
    PDF_PARAGRAPH_LEADING = 1.0
    def to_pdf(pdf)
      pdf.text to_html_fragment(false), :inline_format => true
      pdf.move_down Document::PDF_FONT_SIZE * PDF_PARAGRAPH_LEADING
    end
  end

  class Heading
    PDF_FONT_SIZES = [40, 30, 24].map { |px| Document.pdf_pt(px) }
    PDF_HEADING_LEADING = 0.6
    def to_pdf(pdf)
      size = PDF_FONT_SIZES[level - 1]
      pdf.text text, :size => size, :leading => size * Document::PDF_LEADING, :style => :bold
      pdf.move_down size * PDF_HEADING_LEADING
    end
  end
end


