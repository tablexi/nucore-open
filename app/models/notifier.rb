class Notifier < ActionMailer::Base
  # Welcome user, login credentials.  CC to PI and Department Admin.
  # Who created the account.  How to update.
  def new_user(args)
    subject      'Welcome to NUCore'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"

    part "text/plain" do |p|
        p.body = render_message("new_user.text", :user => args[:user], :password => args[:password])
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("new_user.html", :user => args[:user], :password => args[:password])
  end

  # When a new chart string/PO/CC is added to CoreFac, an email is sent
  # out to the PI, Departmental Administrators, and that particular
  # account's administrator(s)
  def new_account(args)
    subject      'NUCore New Payment Method'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"

    part "text/plain" do |p|
        p.body = render_message("new_account.text", :user => args[:user], :account => args[:account])
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("new_account.html", :user => args[:user], :account => args[:account])
  end

  # Changes to the user affecting the PI or department will alert their
  # PI, the Dept Admins, and Lab Manager.
  def user_update(user)
    subject      'NUCore User Updated'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"

    part "text/plain" do |p|
        p.body = render_message("user_update.text", :user => user)
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("user_update.html", :user => user)
  end

  # Any changes to the financial accounts will alert the PI(s), admin(s)
  # when it is not them making the change. Adding someone to any role of a
  # financial account as well. Roles: Order, Admin, PI.
  def account_update(args)
    subject      'NUCore Payment Method Updated'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"

    part "text/plain" do |p|
        p.body = render_message("account_update.text", :user => args[:user], :account => args[:account])
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("account_update.html", :user => args[:user], :account => args[:account])
  end

  # Custom order forms send out a confirmation email when filled out by a
  # customer. Customer gets one along with PI/Admin/Lab Manager.
  def order_receipt(args)
    subject      'NUCore Order Receipt'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"
    
    part "text/plain" do |p|
        p.body = render_message("order_receipt.text", :user => args[:user], :order => args[:order])
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("order_receipt.html", :user => args[:user], :order => args[:order])
  end

  # Billing sends out the statement for the month. Appropriate users get
  # their version of usage.
  # args = :user, :account, :facility
  def statement(args)
    subject      'NUCore Statement'
    recipients   (TEST_EMAIL_ONLY ? TEST_EMAIL : args[:user].email)
    from         FROM_EMAIL
    sent_on      Time.zone.now
    content_type "multipart/alternative"

    part "text/plain" do |p|
        p.body = render_message("statement.text", :user => args[:user], :facility => args[:facility], :account => args[:account], :statement => args[:statement])
        p.transfer_encoding = "base64"
    end

    part :content_type => "text/html",
        :body => render_message("statement.html", :user => args[:user], :facility => args[:facility], :account => args[:account], :statement => args[:statement])
  end
end
