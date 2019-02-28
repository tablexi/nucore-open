class EditProductForm < TranslatableBaseForm

  include ActiveModel::AttributeAssignment

  def access_control
    return :unrestricted unless requires_approval?

    allows_training_requests? ? :restricted_and_allow_training : :restricted_and_no_training
  end

  def access_control=(control)
    case control.to_s
    when "restricted_and_allow_training"
      self.requires_approval = true
      self.allows_training_requests = true
    when "restricted_and_no_training"
      self.requires_approval = true
      self.allows_training_requests = false
    else
      self.requires_approval = false
      self.allows_training_requests = false
    end
  end

  def update(args)
    assign_attributes(args)
    save
  end

  def access_control_values
    [:unrestricted, :restricted_and_allow_training, :restricted_and_no_training]
  end

end
