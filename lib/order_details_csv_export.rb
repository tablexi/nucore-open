module OrderDetailsCsvExport

  def handle_csv_search
    email_csv_export

    if request.xhr?
      render text: I18n.t("controllers.reports.mail_queued", email: to_email)
    else
      flash[:notice] = I18n.t("controllers.reports.mail_queued", email: to_email)
      redirect_to url_for(params.merge(format: nil, email: nil))
    end
  end

  def email_csv_export
    order_detail_ids = @order_details.respond_to?(:pluck) ? @order_details.pluck(:id) : @order_details.map(&:id)
    AccountTransactionReportMailer.csv_report_email(to_email, order_detail_ids, @date_range_field).deliver_later
  end

  def to_email
    params[:email] || current_user.email
  end

end
