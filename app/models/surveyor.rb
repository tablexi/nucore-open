#
# Knows how to talk to NUCore-tweaked Surveyor webapps
# https://github.com/NUBIC/surveyor
class Surveyor < UrlService
  include Rails.application.routes.url_helpers

  def edit_url(receiver)
    receiver.external_service_receiver.response_data + '/take'
  end


  def new_url(receiver)
    params = {
      :success_url => success_path(receiver),
      # Items below this are deprecated for use with the old version
      # of surveyor and should be removed after upgrading
      :receiver_id => receiver.id,
      :product_id => receiver.product.url_name,
      :survey_id => id,
      :facility_id => receiver.product.facility.url_name,
      :redirect_host => Rails.configuration.surveyor_redirects_to
    }

    location + '?' + params.to_query
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
