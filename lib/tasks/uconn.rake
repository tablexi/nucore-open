namespace :uconn do
  desc "seed data from kennel"
  task kennel_seed: :environment do
    # port of https://gitlab.com/squared-labs/kennel-seeder/blob/master/src/KennelSeeder.php
    require "net/http"
    require "uri"
    require "json"
    def do_kennel_call(path)
      uri = URI.parse("#{SettingsHelper.setting("kennel.url")}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "nucore"
      request["Authorization"] = "Bearer #{SettingsHelper.setting("kennel.token")}"
      request["Content-Type"] = "application/json"

      http.request(request)
    end

    logger = Logger.new(STDOUT)
    pagecount = JSON.parse(do_kennel_call("/count").body)["pages"]
    for i in 1..pagecount
      data = JSON.parse(do_kennel_call("/export?page=#{i}").body)
      data.each { |record|
        drop = false
        if record["group_affil"] == "Affiliate"
          drop = true
        end
        if not record["email"] or record["email"] == ""
          logger.warn "user \"#{record["netid"]}\", a \"#{record["group_affil"]}\", had no email address and was not inserted"
          drop = true
        end
        if drop
          users = User.find_by(username: record["netid"])
          if users
            logger.info "user #{record["netid"]} once existed but is being removed"
            users.delete
          end
          next
        end

        User.find_or_initialize_by(username: record["netid"]).update!(
          :username => record["netid"],
          :first_name => record["first_name"],
          :last_name => record["last_name"],
          :email => record["email"],
        )
        # TODO: add user to billing group based on `group_affil`/`dept_id`, too
      }
      print "imported page #{i} of #{pagecount} (#{i*100/pagecount}%)\r"
      STDOUT.flush
    end
    print "\n"

  end

end
