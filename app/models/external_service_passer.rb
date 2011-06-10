class ExternalServicePasser < ActiveRecord::Base
  belongs_to :external_service
  belongs_to :passer, :polymorphic => true
end