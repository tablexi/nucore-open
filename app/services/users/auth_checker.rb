# frozen_string_literal: true

module Users

  class AuthChecker

    def initialize(user, password)
      @user = user
      @password = password
    end

    def authorized?(action, object)
      return false if @user.nil?

      kiosk_user_ability = Ability.new(@user, object)
      kiosk_user_ability.can?(action, object)
    end

    def authenticated?
      return false if @user.nil?

      if @user.authenticated_locally?
        @user.valid_password?(@password)
      elsif LdapAuthentication.configured?
        @user.valid_ldap_authentication?(@password)
      elsif Settings.saml.present?
        # TODO
      end
    end

  end

end
