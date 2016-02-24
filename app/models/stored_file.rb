class StoredFile < ActiveRecord::Base

  include DownloadableFile

  belongs_to              :product
  belongs_to              :creator, class_name: 'User', foreign_key: 'created_by'
  belongs_to              :order_detail
  validates_presence_of   :name, :file_type, :created_by
  validates_presence_of   :product_id,      if: ->(o) { o.file_type == 'info' || o.file_type == 'template'}
  validates_presence_of   :order_detail_id, if: ->(o) { o.file_type == 'template_result' || o.file_type == 'sample_result'}
  validates_inclusion_of  :file_type, in: %w(info template template_result sample_result import_error import_upload)

  scope :info,              conditions: {file_type: 'info'}
  scope :template,          conditions: {file_type: 'template'}
  scope :template_result,   conditions: {file_type: 'template_result'}
  scope :sample_result,     conditions: {file_type: 'sample_result'}
  scope :import_upload,     conditions: {file_type: 'import_upload'}
  scope :import_error,      conditions: {file_type: 'import_error'}

  validates_attachment_presence :file

  def read
    Paperclip.io_adapters.for(file).read
  end

  # Map file extensions to mime types.
  # Thanks to bug in Flash 8 the content type is always set to application/octet-stream.
  # From: http://blog.airbladesoftware.com/2007/8/8/uploading-files-with-swfupload
  def swf_uploaded_data=(data)
    data.content_type = MIME::Types.type_for(data.original_filename).first.to_s
    self.file = data
  end

end
