# frozen_string_literal: true

module LdapAuthentication

  class UserConverter

    CONVERTABLE_ATTRIBUTES = [:username, :first_name, :last_name, :email].freeze

    def initialize(user_entry)
      @user_entry = user_entry
    end

    def to_user
      ::User.new(attributes)
    end

    def attributes
      CONVERTABLE_ATTRIBUTES.each_with_object({}) do |field, output|
        output[field] = @user_entry.public_send(field)
      end
    end

  end

end
