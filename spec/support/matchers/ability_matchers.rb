RSpec::Matchers.define :be_allowed_to do |action, object|
  description do
    "be allowed to #{action} " +
      if object.respond_to?(:model_name)
        object.model_name.human.pluralize
      else
        "this #{object.class.model_name.human}"
      end.downcase
  end

  match do |ability|
    ability.can?(action, object)
  end
end
