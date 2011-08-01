module Validations
  include NucsErrors
  extend ActiveSupport::Concern

  attr_reader :fund, :dept, :project, :activity, :program, :account
  
  # after_find method is called after a record is loaded from the database
  # this is also serves to instantiate fund, dept, project, etc.
  included do |base|
    base.class_eval <<-METHOD
      def after_find
        validate_chartstring
      end
    METHOD
  end


  def validate_chartstring
    begin
      validator=NucsValidator.new(account_number, NUCore::COMMON_ACCOUNT)
    rescue NucsError => e
      self.errors.add(:account_number, e.message)
      return
    end

    @fund     = validator.fund
    @dept     = validator.department
    @project  = validator.project
    @activity = validator.activity
    @program  = validator.program

    begin
      validator.account_is_open!
    rescue NucsError
      self.errors.add(:account_number, "not found, is inactive, or is invalid")
    end
  end

end
