# frozen_string_literal: true

module Users

  class DefaultPriceGroupSelector

    def call(user)
      user.email_user? ? PriceGroup.external : PriceGroup.base
    end

  end

end
