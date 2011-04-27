# This file contains a base set of data appropriate for development or testing.
# The data can then be loaded with the rake db:bi_seed.

namespace :demo  do
  desc "bootstrap db with data appropriate for demonstration"

  task :seed => :environment do
    new        = OrderStatus.find_or_create_by_name(:name => 'New')
    in_process = OrderStatus.find_or_create_by_name(:name => 'In Process')
    cancelled  = OrderStatus.find_or_create_by_name(:name => 'Cancelled')
    complete   = OrderStatus.find_or_create_by_name(:name => 'Complete')

    facility = Facility.find_or_create_by_name({
      :name              => 'Example Facility',
      :abbreviation      => 'EF',
      :url_name          => 'example',
      :short_description => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam in mi tellus. Nunc ut turpis rhoncus mauris vehicula volutpat in fermentum metus. Sed eleifend purus at nunc facilisis fermentum metus.',
      :description       => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris scelerisque metus et augue elementum ac pellentesque neque blandit. Nunc ultrices auctor velit, et ullamcorper lacus ultrices id. Pellentesque vulputate dapibus mauris, sollicitudin mollis diam malesuada nec. Fusce turpis augue, consectetur nec consequat nec, tristique sit amet urna. Nunc vitae imperdiet est. Aenean gravida, risus eget posuere fermentum, risus odio bibendum ligula, sit amet lobortis enim odio facilisis ipsum. Donec iaculis dolor vitae massa ullamcorper pulvinar. In hac habitasse platea dictumst. Pellentesque iaculis sapien id est auctor a semper odio tincidunt. Suspendisse nec lectus sit amet est imperdiet elementum non sagittis nulla. Sed tempor velit nec sapien rhoncus consequat semper neque malesuada. Nunc gravida justo in felis tempus dapibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis tristique diam dolor. Curabitur lacinia molestie est vel mollis. Ut facilisis vestibulum scelerisque. Aenean placerat purus in nisi auctor scelerisque.</p>',
      :address           => "Example Facility\nFinancial Dept\n111 University Rd.\nEvanston, IL 60201-0111",
      :phone_number      => '(312) 123-4321',
      :fax_number        => '(312) 123-1234',
      :email             => 'example-support@example.com',
      :is_active         => true,
    })

    # create chart strings, which are required when creating a facility account and nufs account
    chart_strings=[
      {
        :budget_period => '-', :fund => '123', :department => '1234567', :project => '12345678',
        :activity => '01', :account => '50617', :starts_at => Time.zone.now-1.week, :expires_at => Time.zone.now+1.year
      },

      {
        :budget_period => '-', :fund => '111', :department => '2222222', :project => '33333333',
        :activity => '01', :account => '50617', :starts_at => Time.zone.now-1.week, :expires_at => Time.zone.now+1.year
      }
    ]

    chart_strings.each do |cs|
      NucsFund.find_or_create_by_value(cs[:fund])
      NucsDepartment.find_or_create_by_value(cs[:department])
      NucsAccount.find_or_create_by_value(cs[:account]) if cs[:account]
      NucsProjectActivity.find_or_create_by_project_and_activity(:project => cs[:project], :activity => cs[:activity])
      NucsGl066.find_or_create_by_fund_and_department_and_project_and_account(cs)
    end


    fa = FacilityAccount.find_or_create_by_facility_id({
      :facility_id     => facility.id,
      :account_number  => '123-1234567-12345678',
      :revenue_account => '50617',
      :is_active       => 1,
      :created_by      => 1,
    })

    item = Item.find_or_create_by_url_name({
      :facility_id         => facility.id,
      :account             => '75340',
      :name                => 'Example Item',
      :url_name            => 'example-item',
      :description         => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>',
      :requires_approval   => false,
      :initial_order_status_id => new.id,
      :is_archived         => false,
      :is_hidden           => false,
      :facility_account_id => fa.id,
    })
    service = Service.find_or_create_by_url_name({
      :facility_id         => facility.id,
      :account             => '75340',
      :name                => 'Example Service',
      :url_name            => 'example-service',
      :description         => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>',
      :requires_approval   => false,
      :initial_order_status_id  => in_process.id,
      :is_archived         => false,
      :is_hidden           => false,
      :facility_account_id => fa.id,
    })
    instrument = Instrument.find_or_create_by_url_name({
      :facility_id         => facility.id,
      :account             => '75340',
      :name                => 'Example Instrument',
      :url_name            => 'example-instrument',
      :description         => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>',
      :initial_order_status_id => new.id,
      :requires_approval   => false,
      :is_archived         => false,
      :is_hidden           => false,
      :facility_account_id => fa.id,
      :relay_ip            => '192.168.10.135',
      :relay_port          => '1',
      :relay_username      => 'admin',
      :relay_password      => 'admin',
    })
    bundle = Bundle.find_or_create_by_url_name({
      :facility_id         => facility.id,
      :account             => '75340',
      :name                => 'Example Bundle',
      :url_name            => 'example-bundle',
      :description         => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non ipsum id odio cursus euismod eu bibendum nisl. Sed nec.</p>',
      :requires_approval   => false,
      :is_archived         => false,
      :is_hidden           => false,
      :facility_account_id => fa.id,
    })
    bundle_item    = BundleProduct.create(:bundle => bundle, :product => item, :quantity => 1)
    bundle_service = BundleProduct.create(:bundle => bundle, :product => service, :quantity => 1)
    @item          = item
    @service       = service
    @instrument    = instrument
    @bundle        = bundle

    sr = ScheduleRule.find_or_create_by_instrument_id({
      :instrument_id      => instrument.id,
      :discount_percent   => 0,
      :start_hour         => 8,
      :start_min          => 0,
      :end_hour           => 19,
      :end_min            => 0,
      :duration_mins      => 5,
      :on_sun             => true,
      :on_mon             => true,
      :on_tue             => true,
      :on_wed             => true,
      :on_thu             => true,
      :on_fri             => true,
      :on_sat             => true
    })
    
    pgnu = PriceGroup.find_or_create_by_name({
      :name => 'Northwestern Base Rate', :is_internal => true, :display_order => 1
    })
    pgnu.save_with_validation(false) # override facility validator

    pgcc = PriceGroup.find_or_create_by_name({
      :name => 'Cancer Center Rate', :is_internal => true, :display_order => 2
    })
    pgcc.save_with_validation(false) # override facility validator
    
    pgex = PriceGroup.find_or_create_by_name({
      :name => 'External Rate', :is_internal => false, :display_order => 3
    })
    pgex.save_with_validation(false) # override facility validator

    [ item, service, bundle ].each do |product|
      PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgnu.id, product.id)
      PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgex.id, product.id)
    end

    pgp=PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgnu.id, instrument.id)
    pgp.reservation_window=14
    pgp.save!

    pgp=PriceGroupProduct.find_or_create_by_price_group_id_and_product_id(pgex.id, instrument.id)
    pgp.reservation_window=14
    pgp.save!
    
    inpp = InstrumentPricePolicy.find_or_create_by_instrument_id_and_price_group_id({
      :instrument_id        => instrument.id,
      :price_group_id       => pgnu.id,
      :start_date           => Date.new(2010,1,1), 
      :usage_rate           => 20,
      :usage_mins           => 15,
      :usage_subsidy        => 0,
      :reservation_rate     => 0,
      :reservation_mins     => 15,
      :reservation_subsidy  => 0,
      :overage_rate         => 0,
      :overage_mins         => 15,
      :overage_subsidy      => 0,
      :minimum_cost         => 0,
      :cancellation_cost    => 0,
    })
    inpp.save_with_validation(false) # override date validator
    itpp = ItemPricePolicy.find_or_create_by_item_id_and_price_group_id({
      :item_id           => item.id,
      :price_group_id    => pgnu.id,
      :start_date        => Date.new(2010,1,1),
      :unit_cost         => 30,
      :unit_subsidy      => 0,
    })
    itpp.save_with_validation(false) # override date validator
    spp = ServicePricePolicy.find_or_create_by_service_id_and_price_group_id({
      :service_id        => service.id,
      :price_group_id    => pgnu.id,
      :start_date        => Date.new(2010,1,1),
      :unit_cost         => 75,
      :unit_subsidy      => 0,
    })
    spp.save_with_validation(false) # override date validator

    user_admin = User.find_by_username('admin')
    unless user_admin
      user_admin = User.new({
        :username   => 'admin',
        :email      => 'admin@example.com',
        :first_name => 'Admin',
        :last_name  => 'Istrator',
      })
      user_admin.password = 'password'
      user_admin.save!
    end
    UserRole.grant(user_admin, UserRole::ADMINISTRATOR)

    user_pi = User.find_by_username('ppi123@example.com')
    unless user_pi
      user_pi = User.new({
        :username   => 'ppi123@example.com',
        :email      => 'ppi123@example.com',
        :first_name => 'Paul',
        :last_name  => 'PI',
      })
      user_pi.password = 'password'
      user_pi.save!
    end

    user_student = User.find_by_username('sst123@example.com')
    unless user_student
      user_student = User.new({
        :username   => 'sst123@example.com',
        :email      => 'sst123@example.com',
        :first_name => 'Sam',
        :last_name  => 'Student',
      })
      user_student.password = 'password'
      user_student.save!
    end

    user_staff = User.find_by_username('ast123@example.com')
    unless user_staff
      user_staff = User.new({
        :username   => 'ast123@example.com',
        :email      => 'ast123@example.com',
        :first_name => 'Alice',
        :last_name  => 'Staff',
      })
      user_staff.password = 'password'
      user_staff.save!
    end
    UserRole.grant(user_staff, UserRole::FACILITY_STAFF, facility)

    user_director = User.find_by_username('ddi123@example.com')
    unless user_director
      user_director = User.new({
        :username   => 'ddi123@example.com',
        :email      => 'ddi123@example.com',
        :first_name => 'Dave',
        :last_name  => 'Director'
      })
      user_director.password = 'password'
      user_director.save
    end
    UserRole.grant(user_director, UserRole::FACILITY_DIRECTOR, facility)

    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id({
      :user_id        => user_pi.id,
      :price_group_id => pgnu.id,
    })
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id({
      :user_id        => user_student.id,
      :price_group_id => pgnu.id,
    })
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id({
      :user_id        => user_staff.id,
      :price_group_id => pgnu.id,
    })
    UserPriceGroupMember.find_or_create_by_user_id_and_price_group_id({
      :user_id        => user_director.id,
      :price_group_id => pgnu.id,
    })

    nufsaccount = NufsAccount.find_or_create_by_account_number({
      :account_number => '111-2222222-33333333',
      :description    => "Paul PI's Chart String",
      :expires_at     => Date.new(2012,1,1),
      :created_by     => user_director.id,
    })
    nufsaccount.account_users_attributes = [{:user_id => user_pi.id, :user_role => 'Owner', :created_by => user_director.id }]
    nufsaccount.save
    nufsaccount.account_users.create(:user_id => user_student.id, :user_role => 'Purchaser', :created_by => user_director.id)
    
    ccaccount = CreditCardAccount.find_or_create_by_account_number({
      :account_number     => 'xxxx-xxxx-xxxx-xxxx',
      :description        => "Paul PI's Credit Card",
      :expires_at         => Date.new(2012,1,1),
      :name_on_card       => 'Paul PI',
      :expiration_month   => '10',
      :expiration_year    => '2014',
      :created_by         => user_director.id,
    })
    ccaccount.account_users_attributes = [{:user_id => user_pi.id, :user_role => 'Owner', :created_by => user_director.id }]
    ccaccount.save
    ccaccount.account_users.create(:user_id => user_student.id, :user_role => 'Purchaser', :created_by => user_director.id)

    poaccount = PurchaseOrderAccount.find_or_create_by_account_number({
      :account_number => '12345',
      :description    => "Paul PI's Purchase Order",
      :expires_at     => Date.new(2012,1,1),
      :created_by     => user_director.id,
      :facility_id    => facility.id,
      :remittance_information => "Billing Dept\nEdward External\n1702 E Research Dr\nAuburn, AL 36830",
    })
    poaccount.account_users_attributes = [{:user_id => user_pi.id, :user_role => 'Owner', :created_by => user_director.id }]
    poaccount.save
    poaccount.account_users.create(:user_id => user_student.id, :user_role => 'Purchaser', :created_by => user_director.id)

    # purchased orders, complete, statements sent, 3 months ago
    sleep 2
    (1..10).each do |i|
      order = get_order(user_student, facility, get_account(user_student), {:purchase => true, :ordered_at => Time.zone.now - (rand(30) + 65).days}) # 94-65 days in the past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation
        at = od.init_purchase_account_transaction
        at.created_by = user_director.id
        at.created_at = od.order.ordered_at + 1.days
        at.save!
        od.change_status!(complete)
      end
    end
    sleep 2
    statement_date = Time.zone.now - 64.days # 64 days in the past
    accounts       = Account.need_statements(facility)
    statement      = Statement.create!({:facility_id => facility.id, :created_by => user_director.id, :created_at => statement_date, :invoice_date => statement_date + 7.days})
    accounts.each do |a|
      a.update_account_transactions_with_statement(statement)
    end

    # purchased orders, complete, statements sent, 2 months ago
    sleep 2
    (1..10).each do |i|
      order = get_order(user_student, facility, get_account(user_student), {:purchase => true, :ordered_at => Time.zone.now - (rand(30) + 32).days}) # 61 - 32 days in the past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation        
        at = od.init_purchase_account_transaction
        at.created_by = user_director.id
        at.created_at = od.order.ordered_at + 1.days
        at.save!
        od.change_status!(complete)
      end
    end
    sleep 2
    statement_date = Time.zone.now - 31.days # 31 days in the past
    accounts       = Account.need_statements(facility)
    statement      = Statement.create!({:facility_id => facility.id, :created_by => user_director.id, :created_at => statement_date, :invoice_date => statement_date + 7.days})
    accounts.each do |a|
      a.update_account_transactions_with_statement(statement)
    end

    # purchased orders, complete details, no statement
    sleep 2
    (1..10).each do |i|
      order = get_order(user_student, facility, get_account(user_student), {:purchase => true, :ordered_at => Time.zone.now - (rand(30) + 1).days}) # 30 - 1 days in past
      order.reload
      order.order_details.each do |od|
        # enter actuals for instruments
        set_instrument_order_actual_cost(od) if od.reservation
        at = od.init_purchase_account_transaction
        at.created_by = user_director.id
        at.created_at = od.order.ordered_at + 1.days
        at.save!
        od.change_status!(complete)
      end
    end

    # purchased orders, new order details, ordered at last X days
    sleep 2
    (1..5).each do |i|
      order = get_order(user_student, facility, get_account(user_student), {:purchase => true, :ordered_at => Time.zone.now - (i*2).days})
    end

  end

  def get_account(user)
    accounts = user.accounts.active
    accounts[rand(accounts.length)]
  end

  def get_order(user, facility, account, args = {})
    # create the order
    o = Order.create({
      :account_id  => account.id,
      :user_id     => user.id,
      :facility_id => facility.id,
      :created_by  => user.id,
    })
    ordered_at = args[:ordered_at] || Time.zone.now - 60*60*24*(rand(30) + 1)
    # create at least one order detail.  20% chance to create an additional detail.

    # create a valid order detail (with price policy and costs)
    products = [@service, @instrument, @item, @bundle]
    return nil if products.empty?
    i = 1
    begin
      product = products[rand(products.length)]
      if product.is_a?(Bundle)
        created_at = (ordered_at - (60*rand(60) + 1))
        group_id   = (o.order_details.collect{|od| od.group_id || 0 }.max || 0) + 1
        product.bundle_products.each do |bp|
          od = OrderDetail.create!({
            :order_id           => o.id,
            :product_id         => bp.product_id,
            :actual_cost     => rand(2),
            :actual_subsidy  => 0,
            :estimated_cost  => rand(2),
            :estimated_subsidy  => 0,
            :quantity           => bp.quantity,
            :created_at         => created_at,
            :bundle_product_id  => product.id,
            :group_id           => group_id
          })
          od.update_account(account)
          od.save!
        end
      else
        od = OrderDetail.create!({
          :order_id        => o.id,
          :product_id      => product.id,
          :actual_cost     => rand(2),
          :actual_subsidy  => 0,
          :estimated_cost  => rand(2),
          :estimated_subsidy  => 0,
          :quantity        => product.is_a?(Item) ? (rand(3) + 1) : 1,
          :created_at      => (ordered_at - (60*rand(60) + 1)),
        })
        # create a reservation
        if product.is_a?(Instrument)
          res = Reservation.create({
            :order_detail_id  => od.id,
            :instrument_id    => product.id,
            :reserve_start_at => Time.zone.parse((ordered_at + 1.days).strftime("%m/%d/%Y") + " #{i+8}:00"),
            :reserve_end_at   => Time.zone.parse((ordered_at + 1.days).strftime("%m/%d/%Y") + " #{i+9}:00"),
          })
          res.save_with_validation(false)
          i += 1
        end
        od.update_account(account)

        od.price_policy=case od.product
                          when Instrument then InstrumentPricePolicy.first
                          when Item then ItemPricePolicy.first
                          when Service then ServicePricePolicy.first
                        end
        od.save!
      end
    end until rand(5) > 0

    # validate and purchase the order
    if args[:purchase]
      o.state = 'validated'
      o.save_with_validation(false)
      o.purchase!
      o.update_attributes!(:ordered_at => ordered_at)
    end
    if args[:validate]
      o.validate_order!
    end
    o
  end

  def set_instrument_order_actual_cost(order_detail)
    res = order_detail.reservation
    res.actual_start_at = res.reserve_start_at
    res.actual_end_at   = res.reserve_end_at
    res.save!
    costs = order_detail.price_policy.calculate_cost_and_subsidy(res)
    order_detail.actual_cost    = costs[:cost]
    order_detail.actual_subsidy = costs[:subsidy]
    order_detail.save!
  end
end
