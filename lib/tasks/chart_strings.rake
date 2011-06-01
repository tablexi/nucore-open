namespace :chart_strings do

  desc "Updates the expiration dates of all +NufsAccount+s based on the latest chart string data"
  task :update_expiration => :environment do
    NufsAccount.all.each do |fs|
      next if fs.suspended?
      validator=NucsValidator.new(fs.account_number)

      now=Time.zone.now
      fs.expires_at=validator.latest_expiration
      fs.expires_at=now if fs.expires_at.nil? || !validator.components_exist?

      # TBD: Could we encounter a valid chart string not in the GL066?
      # If so it might mean that chart string never expires, and
      # that we should set it's expiration date to 1 year from now
      begin        
        if fs.expires_at == now
          fs.save(false) # we're expiring the chart string now so we don't care if validations fail (they'd just cause a headache)
        else
          fs.save!
        end
      rescue => e
        puts "Failed to update NufsAccount #{fs.id} (#{fs.account_number})!: #{e.message}"
      end
    end
  end

end