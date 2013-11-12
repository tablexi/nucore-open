#
# Knows how to talk to NUCore-tweaked Surveyor webapps
# https://github.com/NUBIC/surveyor
class Surveyor < UrlService
  def edit_url(receiver)
    "#{super}/take"
  end

  def url_params(receiver)
    {
      # Items below this are deprecated for use with the old version
      # of surveyor and should be removed after upgrading
      :receiver_id => receiver.id,
      :product_id => receiver.product.url_name,
      :survey_id => id,
      :facility_id => receiver.product.facility.url_name,
      :redirect_host => Rails.configuration.surveyor_redirects_to
    }
  end
end
