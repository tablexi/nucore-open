RSpec.shared_examples_for "a loggable object" do

  # usage note, the user of this shared example is
  # expected to provide an "instance" argument that is
  # a valid instance of the described class that has not
  # yet been saved

  # for example:

  # it_should_behave_like "a loggable object" do
  #   let(:instance) { build(:some_class) }
  # end

  let(:creator) { create(:user) }
  let(:updater) { create(:user) }

  it "audits saves" do
    instance.created_by = creator.id
    instance.save!
    log = LogEvent.last
    expect(log).to have_attributes(
      loggable_id: instance.id, loggable_type: described_class.to_s,
      user: creator, event_type: "create",
      created_at: a_truthy_value)
  end

  it "audits updates" do
    instance.save!
    instance.update(updated_by: updater.id)
    log = LogEvent.last
    expect(log).to have_attributes(
      loggable_id: instance.id, loggable_type: described_class.to_s,
      user: updater, event_type: "update",
      created_at: a_truthy_value)
  end

end
