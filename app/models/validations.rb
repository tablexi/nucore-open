module Validations
  include NucsErrors
  extend ActiveSupport::Concern

  attr_reader :fund, :dept, :project, :activity, :program, :account
  
  # after_find method is called after a record is loaded from the database
  # this is also serves to instantiate fund, dept, project, etc.
  included do |base|
    base.class_eval <<-METHOD
      def after_find
        parse_chartstring
      end
    METHOD
  end

  # parse_chartstring and validate_chartstring used to be one method that was called in after_find
  # the account_is_open! made loading Accounts incredibly slow. - JH 11/21/11
  def parse_chartstring
    validator=NucsValidator.new(account_number, NUCore::COMMON_ACCOUNT)
    if validator
      @fund     = validator.fund
      @dept     = validator.department
      @project  = validator.project
      @activity = validator.activity
      @program  = validator.program
    end
    
    validator
  end
  
  def validate_chartstring
    begin
      validator = parse_chartstring
    rescue NucsError => e
      self.errors.add(:account_number, e.message)
      return
    end
    
    begin
      validator.account_is_open!
    rescue NucsError => e
      msg=e.message
      msg="not found, is inactive, or is invalid" if msg.blank?
      self.errors.add(:account_number, msg)
    end
  end

end
