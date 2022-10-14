module DownloadableFiles

  module Image

    extend ActiveSupport::Concern
    include DownloadableFile

    included do
      if SettingsHelper.feature_on?(:active_storage)
        validates :file, content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]
      else
        validates_attachment :file, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }
      end
    end

  end

end
