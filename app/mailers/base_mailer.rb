# frozen_string_literal: true

class BaseMailer < ActionMailer::Base

  default from: Settings.email.from

  def mail(arguments)
    super
  end

end
