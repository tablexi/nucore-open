# frozen_string_literal: true

#
# A polymorphic join class between an +ExternalService+
# and a class that receives the results of that service
# (the receiver).
class ExternalServiceReceiver < ApplicationRecord

  belongs_to :external_service
  belongs_to :receiver, polymorphic: true

  validates_presence_of :external_service_id, :receiver_id, :response_data

  def respond_to?(symbol, include_private = false)
    super || parsed_response_data.key?(symbol)
  end

  private

  def method_missing(symbol, *args)
    parsed = parsed_response_data
    return parsed[symbol] if parsed.key? symbol
    super
  end

  def parsed_response_data
    JSON.parse(self[:response_data]).symbolize_keys
  rescue TypeError, JSON::ParserError
    {}
  end

end
