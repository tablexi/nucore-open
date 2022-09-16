# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderStatus do
  describe ".new_status" do
    let!(:new_order_status) { create(:order_status, name: "New") }

    it "returns the 'New' order status" do
      expect(described_class.new_status).to eq(new_order_status)
    end
  end

  describe ".initial_statuses" do
    let!(:root_order_statuses) do
      new_status = create(:order_status, name: "New")
      in_process = create(:order_status, name: "In Process")
      canceled = create(:order_status, name: "Canceled")
      complete = create(:order_status, name: "Complete")
      reconciled = create(:order_status, name: "Reconciled")

      {
        new: new_status,
        in_process: in_process,
        canceled: canceled,
        complete: complete,
        reconciled: reconciled,
      }
    end

    let!(:facility) { create(:facility) }
    let!(:facility_status) do
      create(:order_status, facility: facility, parent: root_order_statuses[:new], name: "Brand New")
    end

    let!(:other_status) do
      create(:order_status, facility: create(:facility), parent: root_order_statuses[:new], name: "Other Brand New")
    end

    it "returns all new and in process statuses for the facility" do
      expected_statuses = [
        root_order_statuses[:new].reload,
        facility_status.reload,
        root_order_statuses[:in_process].reload,
      ]

      expect(described_class.initial_statuses(facility)).to eq(expected_statuses)
    end
  end
end
