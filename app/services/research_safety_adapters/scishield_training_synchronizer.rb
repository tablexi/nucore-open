# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldTrainingSynchronizer
    def initialize
      @users = User.active.select(:id, :email)
    end

    def synchronize
      return if api_unavailable?

      ScishieldTraining.transaction do
        ScishieldTraining.delete_all

        @users.find_each do |user|
          adapter = ScishieldApiAdapter.new(user)
          cert_names = adapter.certified_course_names_from_api

          cert_names.each { |cert_name| ScishieldTraining.create(user_id: user.id, course_name: cert_name) }
        end
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    def api_unavailable?
      # Test API responses for 10 random users
      @users.sample(10).map do |user|
        client = ScishieldApiClient.new
        response = client.training_api_request(user.email)
        http_status = response.code

        # track if http status is 5xx or 403 or not
        http_status.match?(/5|403/)
      end.all?
    end
  end

end
