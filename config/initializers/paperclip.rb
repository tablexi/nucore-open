#
# Ensure attachments are saved with URL-friendly names
Paperclip.interpolates :safe_filename do |attachment, style|
  filename(attachment, style).gsub(/#/, '-')
end

# https://github.com/thoughtbot/paperclip#security-validations
text_plain = MIME::Types["text/plain"].first
text_plain.extensions << "rb"
MIME::Types.index_extensions text_plain
