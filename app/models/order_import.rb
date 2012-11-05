class OrderImport < ActiveRecord::Base
  belongs_to :upload_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :error_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :creator, :class_name => :user, :foreign_key => :created_by

  validates_presence_of :upload_file_id, :created_by


  def upload_file=(file)
    self[:upload_file_id]=StoredFile.create!(
      :file => file,
      :file_type => 'import_upload',
      :name => file.original_filename,
      :created_by => created_by
    ).id
  end


  #
  # Tries to import the orders defined in #upload_file.
  # [_returns_]
  #   An OrderImport::Result object
  # [_raises_]
  #   Any encountered error
  def process!
    result=Result.new


    result
  end


  class Result
    attr_accessor :successes, :failures

    def initialize
      self.successes, self.failures=0, 0
    end

    def failed?
      failures > 0
    end

    def blank?
      successes == 0 && failures == 0
    end
  end
end
