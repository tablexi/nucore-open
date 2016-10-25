module BulkEmail

  class JobJsonFieldValidator < ActiveModel::Validator

    def validate(record)
      validate_recipients(record)
      validate_search_criteria(record)
    end

    private

    def validate_recipients(record)
      unless JSON.parse(record.recipients).is_a?(Array)
        record.errors.add(:recipients, :must_be_array)
      end
    rescue JSON::ParserError
      record.errors.add(:recipients, :must_be_array)
    end

    def validate_search_criteria(record)
      unless JSON.parse(record.search_criteria).is_a?(Hash)
        record.errors.add(:search_criteria, :must_be_hash)
      end
    rescue JSON::ParserError
      record.errors.add(:search_criteria, :must_be_hash)
    end

  end

end
