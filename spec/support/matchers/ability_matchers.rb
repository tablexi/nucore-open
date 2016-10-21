RSpec::Matchers.define :be_allowed_to do |action, object|
  description do
    "be allowed to #{action} " +
      if object.respond_to?(:model_name)
        object.model_name.human.pluralize
      elsif object.class.respond_to?(:model_name)
        "this #{object.class.model_name.human}"
      else
        "This #{object.class}"
      end.downcase
  end

  match do |ability|
    ability.can?(action, object)
  end
end

def it_is_allowed_to(actions, object)
  Array(actions).each do |action|
    it { is_expected.to be_allowed_to(action, object) }
  end
end

def it_is_not_allowed_to(actions, object)
  Array(actions).each do |action|
    it { is_expected.not_to be_allowed_to(action, object) }
  end
end
