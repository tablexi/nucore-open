module DownloadableFile
  extend ActiveSupport::Concern

  included do
    has_attached_file :file, Settings.paperclip.to_hash

    # TODO Limit attachment types for safe uploads
    do_not_validate_attachment_file_type :file
  end

  def download_url
    file.send(:directory).files.get_url(
      file.path,
      10.seconds.from_now,
      query: { "response-content-disposition" => "attachment" },
    )
  end
end
