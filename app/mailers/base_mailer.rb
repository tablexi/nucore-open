class BaseMailer < ActionMailer::Base

  default from: Settings.email.from

  def mail(arguments)
    arguments[:to] = Settings.email.fake.to if Settings.email.fake.enabled
    super
  end

end
