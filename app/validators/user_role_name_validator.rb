class UserRoleNameValidator < ActiveModel::Validator

  def validate(record)
    unless UserRole.valid_roles.include?(record.role)
      record.errors[:role] << "is not a valid value"
    end
  end

end
