module Products

  class UserNoteMode

    VALID_MODES = %w(hidden optional required).freeze

    attr_reader :raw_value

    # An array of UserNoteModes representing the possible modes
    # Use this in validations and form collections.
    def self.all
      VALID_MODES.map { |value| new(value) }
    end

    def self.from_string(mode_string)
      if VALID_MODES.include?(mode_string)
        new(mode_string)
      else
        InvalidUserNoteMode.new(mode_string)
      end
    end

    def initialize(raw_value)
      @raw_value = raw_value
      raise ArgumentError, "Invalid value: #{raw_value}" unless VALID_MODES.include?(raw_value)
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

    class InvalidUserNoteMode

      def initialize(raw_value)
        @raw_value = raw_value
      end

      def to_label
        "Invalid User Note Mode: #{@raw_value}"
      end

      def to_s
        to_label
      end
    end
  end

end
