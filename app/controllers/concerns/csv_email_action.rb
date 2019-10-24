# frozen_string_literal: true

module CsvEmailAction

  extend ActiveSupport::Concern

  def send_csv_email_and_respond
    yield(csv_send_to_email)

    if request.xhr?
      render plain: I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
    else
      flash[:notice] = I18n.t("controllers.reports.mail_queued", email: csv_send_to_email)
      redirect_back(fallback_location: url_for)
    end
  end

  private

  def csv_send_to_email
    params[:email] || current_user.email
  end

end
