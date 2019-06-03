module NucoreKfs

  class ChartOfAccounts
    require 'savon'

    def initialize

      # TODO: consider refactoring these to configuration/settings
      wsdl = 'https://kuali.uconn.edu/kfs-prd/remoting/chartOfAccountsInquiry?wsdl'
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
      @joey = User.find_by(username: 'jpo08003')
    end

    def upsert_accounts_for_subfund(subfund_id)
      response = do_call_for_subfund(subfund_id)
      puts("response for subfund '#{subfund_id}':")
      # puts(response.body)
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
        # facility: current_facility,
        current_user: @joey,
        owner_user: account_owner,
        facility: nil,
        params: params
      ).build
      account.save!
      account
    end

    def upsert_account(kfs_soap_data)

      account_name = kfs_soap_data[:account_name]
      puts("account_name = #{account_name}")

      account_open = kfs_soap_data[:status] == "OPEN"

      # build the account_number in the correct format
      object_code = '6610' # always 6610 for the accounts paying
      kfs_account_number = kfs_soap_data[:account_number]
      account_number = "KFS-#{object_code}-#{kfs_account_number}"

      # user roles
      account_owner_netid = kfs_soap_data[:accounts_supervisory_systems_identifier]
      business_admin_netid = kfs_soap_data[:fiscal_officer_identifier]
      puts("account_owner_netid = #{account_owner_netid}")
      puts("business_admin_netid = #{business_admin_netid}")

      account_owner = User.find_by(username: account_owner_netid)
      business_admin = User.find_by(username: business_admin_netid)

      puts("account_owner = #{account_owner}")
      puts("business_admin = #{business_admin}")

      if account_owner == nil || business_admin == nil
        puts("Found nil for account_owner or business_admin. This account will not be added.")
        return
      end

      account = Account.find_by(account_number: account_number)
      # if the account is not in our DB yet, and it is 'OPEN', then build a record for it
      if account == nil && account_open
        account = build_account(account_number, account_owner, account_name)
      end

      if account != nil
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