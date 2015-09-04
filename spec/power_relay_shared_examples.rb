RSpec.shared_examples_for PowerRelay do
  it { is_expected.to allow_mass_assignment_of :ip }
  it { is_expected.to allow_mass_assignment_of :username }
  it { is_expected.to allow_mass_assignment_of :password }
  it { is_expected.to allow_mass_assignment_of :port }
end
