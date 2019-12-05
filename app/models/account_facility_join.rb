# frozen_string_literal: true

class AccountFacilityJoin < ApplicationRecord

  belongs_to :facility, optional: true
  belongs_to :account, optional: true

end
