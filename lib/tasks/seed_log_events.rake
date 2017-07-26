# This is here mostly to seed the LogEvents table so the UI can be tested.
# We might also want to run it in production to give partial historical
# data

namespace :log_events do

  task seed: :environment do

    Account.transaction do

      Account.all.each do |account|
        next if LogEvent.where(loggable: account).present?
        LogEvent.log(
          account, :create, account.created_at,
          User.find_by(id: account.created_by))

        next if account.updated_at.blank?
        LogEvent.log(
          account, :update, account.updated_at,
          User.find_by(id: account.updated_by))
      end

      AccountUser.all.each do |account_user|
        next if LogEvent.where(loggable: account_user).present?
        LogEvent.log(
          account_user, :create, account_user.created_at,
          User.find_by(id: account_user.created_by))

        next if account_user.deleted_at.blank?
        LogEvent.log(
          account, :delete, account_user.deleted_at,
          User.find_by(id: account_user.deleted_by))
      end

      User.all.each do |user|
        next if LogEvent.where(loggable: user).present?
        LogEvent.log(user, :create, user.created_at, nil)
      end

    end

  end

end
