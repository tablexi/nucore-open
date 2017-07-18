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
  let(:destroyer) { create(:user) }

  def most_recent_log_id
    LogEvent.last&.id || 0
  end

  it "audits saves" do
    starting_log_id = most_recent_log_id
    if instance.has_attribute?("created_by")
      instance.created_by = creator.id
      instance.save!
      log = LogEvent.last
      expect(log).to have_attributes(
        loggable_id: instance.id, loggable_type: described_class.to_s,
        user: creator, event_type: "create",
        created_at: a_truthy_value)
    else
      instance.save!
      expect(most_recent_log_id).to eq(starting_log_id)
    end
  end

  it "audits updates" do
    instance.save!
    starting_log_id = most_recent_log_id
    if instance.has_attribute?("updated_by")
      instance.update(updated_by: updater.id)
      log = LogEvent.last
      expect(log).to have_attributes(
        loggable_id: instance.id, loggable_type: described_class.to_s,
        user: updater, event_type: "update",
        created_at: a_truthy_value)
    else
      instance.update(created_at: 1.day.ago)
      expect(most_recent_log_id).to eq(starting_log_id)
    end
  end

  it "audits deletes" do
    instance.save!
    starting_log_id = most_recent_log_id
    if instance.has_attribute?("deleted_by")
      instance.update(deleted_by: destroyer.id)
      instance.destroy
      log = LogEvent.last
      expect(log).to have_attributes(
        loggable_id: instance.id, loggable_type: described_class.to_s,
        user: destroyer, event_type: "delete",
        created_at: a_truthy_value)
      # Note: there's no else clause on this test becuase there's
      # no easy way to guarantee that the incoming instance is
      # deletable in context because of foreign key attachements. 
    end
  end

end
