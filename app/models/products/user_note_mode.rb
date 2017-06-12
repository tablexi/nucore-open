module Products

  class UserNoteMode

    attr_reader :raw_value

    def self.values
      valid_values.map { |value| new(value) }
    end

    def self.valid_values
      %w(hidden optional required).freeze
    end

    def initialize(raw_value)
      @raw_value = raw_value
      freeze
    end

    def to_label
      I18n.t(raw_value, scope: "products.user_notes_field_mode", default: raw_value.titleize)
    end

    def to_s
      raw_value
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

    def required?
      raw_value == "required"
    end

    def visible?
      raw_value != "hidden"
    end

  end

end
