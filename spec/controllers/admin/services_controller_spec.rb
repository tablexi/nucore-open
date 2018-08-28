# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ServicesController do
  it "routes", :aggregate_failures do
    expect(post: "/admin/services/process_one_minute_tasks").to route_to(controller: "admin/services", action: "process_one_minute_tasks")
    expect(post: "/admin/services/process_five_minute_tasks").to route_to(controller: "admin/services", action: "process_five_minute_tasks")
  end

  context "process_one_minute_tasks" do
    it "calls #cancel! on an InstrumentOfflineReservationCanceler" do
      expect_any_instance_of(InstrumentOfflineReservationCanceler).to receive(:cancel!)
      post :process_one_minute_tasks
    end
    it "calls #destroy! on an AdminReservationExpirer" do
      expect_any_instance_of(AdminReservationExpirer).to receive(:expire!)
      post :process_one_minute_tasks
    end
  end

  context "process_five_minute_tasks" do
    it "calls #perform on each object" do
      Admin::ServicesController.five_minute_tasks.each do |task|
        expect_any_instance_of(task).to receive(:perform)
      end
      post :process_five_minute_tasks
    end
  end

end
