module NucoreKfs

  class BannerUpserter
    require 'csv'

    def initialize
      @account_type = 'NufsAccount'
      @kfs_bot = User.find_or_create_by(
        username: NucoreKfs::KFS_BOT_ACCOUNT_USERNAME,
        email: NucoreKfs::KFS_BOT_ACCOUNT_EMAIL,
        first_name: "KFS",
        last_name: "Bot"
      )
      @created_by_user = @kfs_bot
    end

    def parse_file(file_path)
      table = CSV.parse(File.read(file_path), headers: true)

      for row in table
        upsert_account(row)
      end
    end

    def upsert_account(account_data)
      index_code = account_data['IndxCode']
      account_number = "UCH-#{index_code}"
      account_description = account_data['fundDesc']

      account_owner_netid = account_data['PI_NetId']
      account_owner = User.find_by(username: account_owner_netid)

      if account_owner == nil
        puts("Found nil for account_owner. This account will not be added.")
        return
      end
      puts("account_number = #{account_number} | account_owner_netid = #{account_owner_netid} | account_owner = #{account_owner.id}")

      account = Account.find_by(account_number: account_number)
      # if the account is not in our DB yet, and it is 'OPEN', then build a record for it
      if account == nil
        puts("account_number = #{account_number} does not exist yet - building account...")
        account = build_account(account_number, account_owner, account_description)
      end

      if account != nil
        puts("account_number = #{account_number} exists - updating account...")
        # set the correct "Business Admin" and Owners for the account
        set_owner_for_account(account, account_owner)

        puts("users for account = #{account.id}")
        for user in account.account_users
          puts("user_id = #{user.user_id} role = #{user.user_role}")
        end

        account.save!
      end
    end

    def build_account(account_number, account_owner, description)
      params = ActionController::Parameters.new({
        :nufs_account => {
          :account_number => account_number,
          :description => description
        }
      })
      account = AccountBuilder.for(@account_type).new(
        account_type: @account_type,
        current_user: @created_by_user,
        owner_user: account_owner,
        facility: nil,
        params: params
      ).build
      account.save!
      account
    end

    def set_owner_for_account(account, owner_user)
      existing_owner = account.owner

      if existing_owner == nil
        puts("set_owner_for_account - account had no owner")
        create_account_owner_record(account, owner_user)
      elsif existing_owner.user.username != owner_user.username
        puts("set_owner_for_account - existing_owner = #{existing_owner.user.username}")
        puts("set_owner_for_account - replacing existing_owner with owner_user = #{owner_user.username}")
        existing_owner.touch(:deleted_at)
        create_account_owner_record(account, owner_user)
        existing_owner.save!
      end
    end

    def create_account_owner_record(account, owner)
      puts("create_account_owner_record for account = #{account.id} and user = #{owner.username}")
      # If this user was previously listed on the account in another role, delete that association
      existing_user = account.account_users.where(user_id: owner.id, deleted_at: nil).first

      if existing_user != nil
        puts("existing_user = #{existing_user.user.username}")
        # If the user is already the owner, we don't need to do anything else
        if existing_user.user_role == AccountUser::ACCOUNT_OWNER
          return
        end
        existing_user.touch(:deleted_at)
      end

      result = account.account_users.create(
        user: owner,
        created_by_user: @created_by_user,
        user_role: AccountUser::ACCOUNT_OWNER
      )
      result.save!
    end
  
  end

end
