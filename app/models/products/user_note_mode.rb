module Products

  class UserNoteMode

    VALID_VALUES = %w(hidden optional required).freeze

    attr_reader :raw_value

    def self.values
      VALID_VALUES.map { |value| new(value) }
    end

    def initialize(raw_value)
      detitleized = raw_value.to_s.underscore.gsub(/\s+/, "_")
      if VALID_VALUES.include?(detitleized)
        @raw_value = detitleized
      elsif I18n.t(translation_scope).invert.key?(raw_value)
        @raw_value = I18n.t(translation_scope).invert[raw_value]
      else
        raise ArgumentError, "Invalid value: #{raw_value}"
      end
      freeze
    end

    def required?
      raw_value == "required"
    end

    def visible?
      raw_value != "hidden"
    end

    def to_s
      I18n.t(raw_value, scope: translation_scope, default: raw_value.titleize)
    end

    def ==(other)
      case other
      when self.class
        raw_value == other.raw_value
      when String
        raw_value == other
      else
        false
      end
    end

    private

    def translation_scope
      "products.user_notes_field_mode"
    end

  end

end
