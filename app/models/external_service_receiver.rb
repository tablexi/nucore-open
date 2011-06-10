class ExternalServiceReceiver < ActiveRecord::Base
  belongs_to :external_service
  belongs_to :receiver, :polymorphic => true
end