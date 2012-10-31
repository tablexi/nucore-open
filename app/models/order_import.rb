class OrderImport < ActiveRecord::Base
  belongs_to :upload_file, :class_name => :stored_file, :dependent => :destroy
  belongs_to :error_file, :class_name => :stored_file, :dependent => :destroy
  belongs_to :creator, :class_name => :user, :foreign_key => :created_by

  validates_presence_of :upload_file_id, :created_by
end
