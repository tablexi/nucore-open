module NucoreKfs

  class ChartOfAccounts
    require 'savon'

    def initialize

      # TODO: consider refactoring these to configuration/settings
      # wsdl = 'https://kuali.uconn.edu/kfs-uat/remoting/chartOfAccountsInquiry?wsdl'
      wsdl = 'https://kualinp.uconn.edu/kfs-uat/remoting/chartOfAccountsInquiry?wsdl'
      # required workaround: override WSDL namespace since the targetNamespace
      # specified by the WSDL does not match what the SOAP endpoint expects
      namespace = 'http://kfs.kuali.org/core/v5_0'

      @client = Savon.client(
        wsdl: wsdl,
        namespace: namespace,
        # ssl_verify_mode: :none,
        log_level: :info,
        log: true,
        pretty_print_xml: true,
      )

      @account_type = 'NufsAccount'
      @kfs_bot = User.find_or_create_by(
        username: NucoreKfs::KFS_BOT_ACCOUNT_USERNAME,
        email: NucoreKfs::KFS_BOT_ACCOUNT_EMAIL,
        first_name: "KFS",
        last_name: "Bot"
      )

      @created_by_user = @kfs_bot
    end

    def upsert_accounts_for_subfund(subfund_id)
      response = do_call_for_subfund(subfund_id)
      accounts = response.body[:get_accounts_response][:return][:account]
      for account in accounts
        upsert_account(account)
      end
    end

    def do_call_for_subfund(subfund_id)
      subfunds = [
        { subFund: subfund_id },
      ]

      response = @client.call(:get_accounts, headers: { 'SOAPAction' => ''}) do
        message({ arg0: subfunds })
      end
    end

    def build_account(account_number, account_owner, account_name)
      params = ActionController::Parameters.new({
        :nufs_account => {
          :account_number => account_number,
          :description => account_name
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

    def create_business_admin_record(account, business_admin_user)
      puts("create_business_admin_record for account = #{account.id} and user = #{business_admin_user.username}")
      # If this user was previously listed on the account in another role, delete that association
      existing_user = account.account_users.where(user_id: business_admin_user.id).first
      if existing_user != nil
        existing_user.touch(:deleted_at)
        existing_user.save!
      end
      account.account_users.create(
        user: business_admin_user,
        created_by_user: @created_by_user,
        user_role: AccountUser::ACCOUNT_ADMINISTRATOR
      )
    end

    def set_business_admin_for_account(account, business_admin_user)
      puts("set_business_admin_for_account - business_admin_user = #{business_admin_user.username}")
      # see if there is an existing business_admin created by the bot
      bot_added_admins = account.business_admins.where(created_by_user: @created_by_user)
      puts("bot_added_admins.count = #{bot_added_admins.count}")
      if bot_added_admins.count > 0
        # delete any that are different from the current one in the data feed
        for current_admin in bot_added_admins
          puts("set_business_admin_for_account - current_admin = #{current_admin.user.username}")
          if current_admin.user.username != business_admin_user.username
            current_admin.touch(:deleted_at)
            current_admin.save!
          end
        end
      end
      # if business_admin_user is not on the account, add them
      if account.business_admins.where(user_id: business_admin_user.id).count == 0
        create_business_admin_record(account, business_admin_user)
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

    def upsert_account(kfs_soap_data)

      account_name = kfs_soap_data[:account_name]
      puts("account_name = #{account_name}")

      account_status = kfs_soap_data[:status]
      account_open = account_status == "OPEN"

      # build the account_number in the correct format
      object_code = '6610' # always 6610 for the accounts paying
      kfs_account_number = kfs_soap_data[:account_number]
      account_number = "KFS-#{kfs_account_number}-#{object_code}"
      puts("account_number = #{account_number} | account_open = #{account_open} (status = #{account_status})")

      # user roles
      account_owner_netid = kfs_soap_data[:accounts_supervisory_systems_identifier]
      business_admin_netid = kfs_soap_data[:fiscal_officer_identifier]
      puts("account_number = #{account_number} | account_owner_netid = #{account_owner_netid} | business_admin_netid = #{business_admin_netid}")

      account_owner = User.find_by(username: account_owner_netid)
      business_admin = User.find_by(username: business_admin_netid)

      if account_owner == nil || business_admin == nil
        puts("Found nil for account_owner or business_admin. This account will not be added.")
        return
      end
      puts("account_number = #{account_number} | account_owner = #{account_owner.id} | business_admin = #{business_admin.id}")

      account = Account.find_by(account_number: account_number)
      # if the account is not in our DB yet, and it is 'OPEN', then build a record for it
      if account == nil && account_open
        puts("account_number = #{account_number} does not exist yet - building account...")
        account = build_account(account_number, account_owner, account_name)
      end

      if account != nil
        puts("account_number = #{account_number} exists - updating account...")
        # set the correct "Business Admin" and Owners for the account
        set_owner_for_account(account, account_owner)
        set_business_admin_for_account(account, business_admin)

        puts("users for account = #{account.id}")
        for user in account.account_users
          puts("user_id = #{user.user_id} role = #{user.user_role}")
        end

        account.save!

        # ensure the account is flagged as open/closed as appropriate
        if account.suspended? && account_open
          account.unsuspend
          puts("unsuspending account: #{account_number}")
        end
        if !account.suspended? && !account_open
          account.suspend
          puts("suspending account: #{account_number}")
        end
      end
    end

  end

end
