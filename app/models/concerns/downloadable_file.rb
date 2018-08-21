# frozen_string_literal: true

module DownloadableFile

  extend ActiveSupport::Concern

  included do
    has_attached_file :file, PaperclipSettings.config.merge(validate_media_type: false)

    # TODO: Limit attachment types for safe uploads
    do_not_validate_attachment_file_type :file
  end

  def download_url
    if PaperclipSettings.fog?
      # This is a workaround due to a bug or limitation in fog to generate a
      # private, expiring URL and have it force a download.
      #
      # This suggested technique is not returning a valid URL:
      #   https://github.com/fog/fog/issues/1776#issuecomment-16868662
      # For more background:
      #   https://github.com/tablexi/chidry/pull/422#issuecomment-74940630
      file.send(:directory).files.get_url(
        file.path,
        10.seconds.from_now,
        query: {
          "response-content-type" => file_content_type,
          "response-content-disposition" => "attachment",
        },
      )
    else
      file.url
    end
  end

end
