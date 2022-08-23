# frozen_string_literal: true

module DownloadableFile

  extend ActiveSupport::Concern

  included do
    if SettingsHelper.feature_on?(:active_storage)
      # TODO: Limit attachment types for safe uploads
      has_one_attached :file

      def assign_attributes(new_attributes)
        if SettingsHelper.feature_on?(:active_storage)
          # Ensure the file name and file_type are set first when attaching a StringIO
          # see #file= method below
          assign_first = new_attributes.extract!(:name, :file_type)
          super(assign_first) unless assign_first.empty?
        end
        super(new_attributes)
      end

    else
      has_attached_file :file, PaperclipSettings.config.merge(
        validate_media_type: false,
        s3_url_options: { response_content_disposition: "attachment" } # this is ignored when using local storage
      )

      # TODO: Limit attachment types for safe uploads
      do_not_validate_attachment_file_type :file
    end
  end

  def download_url
    if SettingsHelper.feature_on?(:active_storage)
      file
    else
      file.expiring_url
    end
  end

  def read_attached_file
    if SettingsHelper.feature_on?(:active_storage)
      return file.download if persisted?

      attachable = attachment_changes["file"]&.attachable

      if attachable.is_a?(Hash)
        read_io = attachable[:io]&.read
        attachable[:io].rewind
        read_io
      else
        attachable&.read
      end
    else
      Paperclip.io_adapters.for(file).read
    end
  end

  def file_path
    if SettingsHelper.feature_on?(:active_storage)
      file.service.path_for("file")
    else
      file.path
    end
  end

  def rename(attr, value)
    if SettingsHelper.feature_on?(:active_storage)
      file.filename = value
    else
      file.instance_write(attr, value)
    end
  end

  def file=(attachable)
    attachable_is_a_file = (attachable.is_a?(StringIO) || attachable.is_a?(File))

    if attachable_is_a_file && SettingsHelper.feature_on?(:active_storage)
      filename = try(:name) || "untitled"
      content_type = try(:file_type) || "text/csv"
      super({ io: attachable, filename: filename, content_type: content_type })
    else
      super
    end
  end

end
