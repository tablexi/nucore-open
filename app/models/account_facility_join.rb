class AccountFacilityJoin < ApplicationRecord

  belongs_to :facility
  belongs_to :account

end
