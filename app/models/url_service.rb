#
# A UrlService is an +ExternalService+ that is
# accessed via HTTP/URLs.
class UrlService < ExternalService

  #
  # Provides a URL for editing data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver in a polymorphic +ExternalServiceReceiver+
  #   relationship. Often its #response_data is useful
  def edit_url(receiver)
    raise 'subclass must implement!'
  end


  #
  # Provides a URL for entering new data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver of a polymorphic +ExternalServiceReceiver+
  #   relationship. Useful for providing pass-thru HTTP param data
  #   to the external service.
  def new_url(receiver)
    raise 'subclass must implement!'
  end

end