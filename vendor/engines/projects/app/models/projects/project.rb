module Projects

  class Project < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    belongs_to :facility, foreign_key: :facility_id

    validates :facility_id, presence: true
    validates :name,
              presence: true,
              uniqueness: { case_sensitive: false, scope: :facility_id }

  end

end
