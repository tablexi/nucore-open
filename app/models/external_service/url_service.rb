#
# A UrlService is an +ExternalService+ that is
# accessed via HTTP/URLs.
class UrlService < ExternalService
  include Rails.application.routes.url_helpers


  #
  # Provides a URL for entering new data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver of a polymorphic +ExternalServiceReceiver+
  #   relationship. Useful for providing pass-thru HTTP param data
  #   to the external service.
  def new_url(receiver, request = nil)
    params = {
      success_url: success_path(receiver, request)
    }

    "#{location}?#{params.to_query}"
  end


  private

  def success_path(receiver, request = nil)
    params = {  :facility_id => receiver.product.facility.url_name,
                :service_id => receiver.product.url_name,
                :external_service_id => id,
                :receiver_id => receiver.id
              }
    params.merge!(:host => request.host, :port => request.port, :protocol => request.protocol) if request
    complete_survey_url(params)
  end

end
