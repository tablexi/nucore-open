#
# A polymorphic join class between an +ExternalService+
# and a class that receives the results of that service
# (the receiver).
class ExternalServiceReceiver < ActiveRecord::Base
  belongs_to :external_service
  belongs_to :receiver, :polymorphic => true

  validates_presence_of :external_service_id, :receiver_id, :response_data


  def respond_to?(symbol, include_private=false)
    super || parsed_response_data.has_key?(symbol)
  end


  private

  def method_missing(symbol, *args)
    parsed = parsed_response_data
    return parsed[symbol] if parsed.has_key? symbol
    super
  end


  def parsed_response_data
    return {} unless response_data
    JSON.parse(response_data).symbolize_keys
  end

end
