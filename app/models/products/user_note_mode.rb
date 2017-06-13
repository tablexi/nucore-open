module Products

  class UserNoteMode

    VALID_MODES = %w(hidden optional required).freeze

    attr_reader :raw_value

    # An array of UserNoteModes representing the possible modes
    # Use this in validations and form collections.
    def self.values
      VALID_MODES.map { |value| new(value) }
    end

    def initialize(raw_value)
      @raw_value = raw_value
      freeze
    end

    def required?
      raw_value == "required"
    end

    def visible?
      raw_value != "hidden"
    end

    # to_label is a method by simple_form to generate the option name in dropdowns
    # that it tries before falling back to to_s
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

  end

end
