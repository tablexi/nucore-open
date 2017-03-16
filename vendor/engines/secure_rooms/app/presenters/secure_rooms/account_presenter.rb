module SecureRooms

  class AccountPresenter < SimpleDelegator

    def self.wrap(accounts)
      accounts.map { |account| new(account) }
    end

    def to_json
      {
        id: id,
        type: type,
        description: description,
        account_number: account_number,
        expiration_month: expiration_month,
        expiration_year: expiration_year,
        owner_name: owner_user_name,
      }.to_json
    end

  end

end
