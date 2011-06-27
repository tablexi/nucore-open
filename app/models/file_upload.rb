class FileUpload < ActiveRecord::Base
  belongs_to              :product
  belongs_to              :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to              :order_detail
  validates_presence_of   :name, :file_type, :created_by
  validates_presence_of   :product_id,      :if => lambda {|o| o.file_type == 'info' || o.file_type == 'template'}
  validates_presence_of   :order_detail_id, :if => lambda {|o| o.file_type == 'template_result' || o.file_type == 'sample_result'} 
  validates_inclusion_of  :file_type, :in => %w(info template template_result sample_result)
  has_attached_file       :file,
                          :storage => :filesystem,
                          :url => "#{ENV['RAILS_RELATIVE_URL_ROOT']}/:attachment/:id_partition/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id_partition/:style/:basename.:extension"
  validates_attachment_presence :file

  scope :info,              :conditions => {:file_type => 'info'}
  scope :template,          :conditions => {:file_type => 'template'}
  scope :template_result,   :conditions => {:file_type => 'template_result'}
  scope :sample_result,     :conditions => {:file_type => 'sample_result'}

  # Map file extensions to mime types.
  # Thanks to bug in Flash 8 the content type is always set to application/octet-stream.
  # From: http://blog.airbladesoftware.com/2007/8/8/uploading-files-with-swfupload
  def swf_uploaded_data=(data)
    data.content_type = MIME::Types.type_for(data.original_filename)
    self.file = data
  end

end