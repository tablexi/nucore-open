#
# Knows how to talk to NUCore-tweaked Surveyor webapps
# https://github.com/NUBIC/surveyor
class Surveyor < UrlService
  def edit_url(receiver)
    "#{super}/take"
  end
end
