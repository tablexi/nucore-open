#
# A polymorphic join class between an +ExternalService+
# and a class that passes off work to that service
# (the passer).
class ExternalServicePasser < ActiveRecord::Base
  belongs_to :external_service
  belongs_to :passer, :polymorphic => true

  validates_presence_of :external_service_id, :passer_id
end