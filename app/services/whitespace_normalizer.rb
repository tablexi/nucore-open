# frozen_string_literal: true

class WhitespaceNormalizer

  def self.normalize(text)
    new(text).normalize
  end

  def initialize(text)
    @text = text
  end

  def normalize
    result = normalize_spaces(@text)
    result = normalize_new_lines(result)
    result
  end

  private

  def normalize_spaces(text)
    text.gsub(/\p{Blank}/, " ")
  end

  def normalize_new_lines(text)
    text.gsub(/\R+/, "\n")
  end

end
