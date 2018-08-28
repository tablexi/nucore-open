# frozen_string_literal: true

namespace :reservations do
  desc "notify users with upcoming reservations for offline instruments"
  task notify_offline: :environment do
    UpcomingOfflineReservationNotifier.new.notify
  end
end
