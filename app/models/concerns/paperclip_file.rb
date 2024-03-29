# frozen_string_literal: true

module PaperclipFile

  extend ActiveSupport::Concern

  included do
    has_attached_file :file, PaperclipSettings.config.merge(
      validate_media_type: false,
      s3_url_options: { response_content_disposition: "attachment" } # this is ignored when using local storage
    )

    # TODO: Limit attachment types for safe uploads
    do_not_validate_attachment_file_type :file

    after_validation :clean_up_paperclip_errors
  end

  def download_url
    file.expiring_url
  end

  def delete_file
    file.clear
  end

  def read_attached_file
    Paperclip.io_adapters.for(file).read
  end

  def file_path
    file.path
  end

  def update_filename(value)
    file.instance_write(:file_name, value)
  end

  def file=(attachable)
    super
  end

  private

  # This is because paperclip duplicates error messages
  # See: https://github.com/thoughtbot/paperclip/pull/1554 and
  # https://github.com/thoughtbot/paperclip/commit/2aeb491fa79df886a39c35911603fad053a201c0
  def clean_up_paperclip_errors
    errors.delete(:file) if errors[:file] == errors[:file_file_size]
  end

end
