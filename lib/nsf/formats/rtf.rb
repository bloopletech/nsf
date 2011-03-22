require 'rtf'
require 'ruby-rtf'

module Nsf
  class Document
    def self.from_rtf(text)
      nodes = []
      current_text = ""

      (RubyRTF::Parser.new.parse(text).sections + [{ :text => '', :paragraph => true, :modifiers => {} }]).each do |sec|
        puts sec.inspect
        new_text = sec[:text]

        unless new_text.gsub(/[[:space:]]+/, ' ').blank?
          new_text = "*#{new_text}*" if sec[:modifiers][:bold]
          new_text = "_#{new_text}_" if sec[:modifiers][:italic]
        end

        current_text << new_text

        if sec[:modifiers][:paragraph]
          paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
          nodes << Paragraph.new(paragraph_text) if paragraph_text.present?
          current_text = ""
        end
      end

      Document.new(nodes)
    end

    def to_rtf
      doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, 'Times New Roman'))

      nodes.each do |node|
        doc.paragraph << node.to_rtf
      end
      
      doc.to_rtf
    end
  end
     
  class Paragraph
    #RTF_BOLD = RTF::CharacterStyle.new
    #RTF_BOLD.bold = true

    #RTF_ITALIC = RTF::CharacterStyle.new
    #RTF_ITALIC.italic = true

    def to_rtf
      #cn = RTF::CommandNode.new('', '')
      #cn.paragraph do |p|
      #  elements = @text.split(/[\*_]/)
      #end
      @text.gsub("\n", " ")
    end
  end

  class Fixedblock < Paragraph
    def to_rtf
      @text.gsub("\n", " ")
    end
  end

  class Heading
    def to_rtf
      @text.gsub("\n", " ")
    end
  end
end