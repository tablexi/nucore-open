#
# A UrlService is an +ExternalService+ that is
# accessed via HTTP/URLs.
class UrlService < ExternalService
  include Rails.application.routes.url_helpers

  attr_accessor :request

  #
  # Provides a URL for editing data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver in a polymorphic +ExternalServiceReceiver+
  #   relationship. Often its #response_data is useful
  def edit_url(receiver)
    show_url(receiver)
  end


  # Provides a URL for displaying data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver in a polymorphic +ExternalServiceReceiver+
  #   relationship. Often its #response_data is useful
  def show_url(receiver)
    receiver.external_service_receiver.response_data
  end


  #
  # Provides a URL for entering new data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver of a polymorphic +ExternalServiceReceiver+
  #   relationship. Useful for providing pass-thru HTTP param data
  #   to the external service.
  def new_url(receiver)
    params = {
      :success_url => success_path(receiver)
    }.merge(url_params(receiver))

    "#{location}?#{params.to_query}"
  end

  #
  # Additional url parameters to be included in the new_url
  # Can be overridden in subclasses
  def url_params
    {}
  end

  private

  def success_path(receiver)
    params = {  :facility_id => receiver.product.facility.url_name,
                :service_id => receiver.product.url_name,
                :external_service_id => id,
                :receiver_id => receiver.id
              }
    params.merge!(:host => request.host, :port => request.port, :protocol => request.protocol) if request
    complete_survey_url(params)
  end
end
