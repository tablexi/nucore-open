# frozen_string_literal: true

#
# Ensure attachments are saved with URL-friendly names
Paperclip.interpolates :safe_filename do |attachment, style|
  filename(attachment, style).tr('#', "-")
end

Paperclip.interpolates :rails_relative_url_root do |_, _|
  ENV["RAILS_RELATIVE_URL_ROOT"] || ""
end

# XLS files created by the spreadsheet gem have problems with their filetypes
# https://github.com/zdavatz/spreadsheet/issues/97
Paperclip.options[:content_type_mappings] = {
  xls: "CDF V2 Document, No summary info",
}

class PaperclipSettings

  def self.config
    secrets = Hash(Rails.application.secrets.paperclip).symbolize_keys
    Settings.paperclip.to_hash.merge(secrets)
  end

  def self.fog?
    config[:storage] == "fog"
  end

end
