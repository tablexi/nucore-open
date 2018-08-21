# frozen_string_literal: true

namespace :secure_rooms do
  namespace :order_details do
    desc "mark order_details with long-running occupancies as orphaned"
    task orphan_occupancies: :environment do
      SecureRooms::AutoOrphanOccupancy.new.perform
    end
  end
end
