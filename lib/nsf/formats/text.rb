module Nsf
  class Document
    def self.from_text(text)
      blocks = []

      in_paragraph = true
      current_text = ""
      prev_line = ""
      lines = text.split("\n")
      lines.each do |line|
        if line.blank? || line == lines.last || (current_text.present? && ((lsp(line) < lsp(prev_line))))
          if in_paragraph || line == lines.last
            in_paragraph = false

            current_text << " " << line unless line.blank?

            if current_text != ""
              paragraph_text = current_text.gsub(/[[:space:]]+/, ' ').strip
              blocks << paragraph_text if paragraph_text.present?
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

    # LSP == Leading SPaces
    def self.lsp(str)
      str =~ /^([[:space:]]+)/
      $1 ? $1.length : 0
    end
  end
end