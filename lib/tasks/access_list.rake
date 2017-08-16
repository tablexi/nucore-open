namespace :access_list do

  desc "Import a CSV containing access list information. Dry run by default."
  task :import, [:filename, :for_real] => :environment do |_t, args|
    products = Hash.new { |h, k| h[k] = Product.find_by!(name: k) }

    product_users = []

    CSV.foreach(args[:filename], skip_lines: /^,*$/).each do |row|
      product = products[row[0]]
      group = product.product_access_groups.find_by!(name: row[1]) if row[1].present?
      user = User.find_by!(username: row[2])

      puts "Adding #{user} to #{product}: #{group.try!(:name)}"
      product_users << ProductUser.new(product: product, user: user, product_access_group: group, approved_by: 0)
    end

    if args[:for_real]
      ProductUser.transaction do
        product_users.each(&:save!)
      end
      puts "#{product_users.count} users added to access lists"
    else
      puts "Dry run complete: #{product_users.count} would have been created"
    end
  end

end
