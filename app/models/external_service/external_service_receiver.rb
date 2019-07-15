# frozen_string_literal: true

class ExternalServiceReceiver < ApplicationRecord

  belongs_to :external_service
  belongs_to :receiver, polymorphic: true

  validates_presence_of :external_service_id, :receiver_id, :response_data

  def show_url
    parsed_response_data[:show_url]
  end

  def edit_url
    parsed_response_data[:edit_url]
  end

  private

  def parsed_response_data
    JSON.parse(response_data).symbolize_keys
  rescue TypeError, JSON::ParserError
    {}
  end

end
