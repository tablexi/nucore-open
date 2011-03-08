module Validations
  include NucsErrors

  attr_reader :fund, :dept, :project, :activity, :program, :account
  
  # after_find method is called after a record is loaded from the database
  # this is also serves to instantiate fund, dept, project, etc.
  def after_find
    validate_chartstring
  end

  def validate_chartstring
    begin
      validator=NucsValidator.new(account_number)
    rescue NucsError => e
      self.errors.add(:account_number, e.message)
      return
    end

    @fund     = validator.fund
    @dept     = validator.department
    @project  = validator.project
    @activity = validator.activity
    @program  = validator.program

    unless validator.components_exist?
      self.errors.add(:account_number, "not found or is inactive")
      return
    end
  end

end
