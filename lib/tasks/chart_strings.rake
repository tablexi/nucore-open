namespace :chart_strings do

  desc "Updates the expiration dates of all +NufsAccount+s based on the latest chart string data"
  task :update_expiration => :environment do
    NufsAccount.all.each do |fs|
      next if fs.suspended?
      latest_expiration=NucsValidator.new(fs.account_number).latest_expiration
      fs.expires_at=latest_expiration ? latest_expiration : Time.zone.now

      begin
        fs.save!
      rescue => e
        puts "Failed to update NufsAccount #{fs.id} (#{fs.account_number})!: #{e.message}"
      end
    end
  end

end