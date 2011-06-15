#
# A polymorphic join class between an +ExternalService+
# and a class that receives the results of that service
# (the receiver).
class ExternalServiceReceiver < ActiveRecord::Base
  belongs_to :external_service
  belongs_to :receiver, :polymorphic => true

  validates_presence_of :external_service_id, :receiver_id, :response_data
end