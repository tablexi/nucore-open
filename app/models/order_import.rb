class OrderImport < ActiveRecord::Base
  belongs_to :upload_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :error_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :creator, :class_name => :user, :foreign_key => :created_by

  validates_presence_of :upload_file_id, :created_by


  #
  # Tries to import the orders defined in #upload_file.
  # [_returns_]
  #   An OrderImport::Result object
  # [_raises_]
  #   Any encountered error
  def process!
    result=Result.new
    # Process each line of CSV file in #upload_file.
    #
    # if fail_on_error
    #   If an error is encountered create the exact
    #   same CSV with the error annotated in a new error column.
    #   Save error file to #error_file.
    # else
    #   Save all valid orders and keep track of any failures.
    #   At end of processing create a #error_file out of the failures.
    #   Include each failed line with the error annotated in a new error column.
    # end
    #
    # Be sure to honor #send_receipts
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
