# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldTrainingSynchronizer
    def initialize
      @users = User.select(:id, :email)
      @client = ScishieldApiClient.new
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
      acceptable_codes = ["200", "404"] # do unacceptable instead, 5xx & 403

      @users.sample(10).each do |user|
        response = @client.api_request(user.email)
        http_status = response.code
        error_count += 1 unless acceptable_codes.include? http_status
      end

      # Assume the API is down if there are more than 9 errors
      error_count < 10
    end
  end

end
