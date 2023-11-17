# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldTrainingSynchronizer
    def initialize
      @users = User.select(:id, :email)
    end

    def synchronize
      return unless api_available?

      ScishieldTraining.transaction do
        ScishieldTraining.delete_all

        @users.each do |user|
          adapter = ScishieldApiAdapter.new(user)
          cert_names = adapter.certified_course_names_from_api

          cert_names.each { |cert_name| ScishieldTraining.create(user_id: user.id, course_name: cert_name) }
        end
      rescue StandardError
        raise ActiveRecord::Rollback
      end
    end

    def api_available?
      error_count = 0

      # Test API responses for 10 random users
      @users.sample(10).each do |user|
        client = ScishieldApiClient.new
        response = client.api_request(user.email)
        http_status = response.code

        # Increment errors if http status is 5xx or 403
        error_count += 1 if http_status.match?(/5|403/)
      end

      # Assume the API is up if there are less than 10 errors
      error_count < 10
    end
  end

end
