shared_examples_for PowerRelay do
  it { should allow_mass_assignment_of :ip }
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :port }
  it { should validate_uniqueness_of(:port).scoped_to(:ip) }

  context 'with relay' do

  end
end
