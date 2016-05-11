module Projects

  class Project < ActiveRecord::Base

    include ActiveModel::ForbiddenAttributesProtection

    belongs_to :facility, foreign_key: :facility_id
    has_many :order_details, inverse_of: :project

    validates :facility_id, presence: true
    validates :name,
              presence: true,
              uniqueness: { case_sensitive: false, scope: :facility_id }

    scope :active, -> { where(active: true) }

    def to_s
      name
    end

  end

end
