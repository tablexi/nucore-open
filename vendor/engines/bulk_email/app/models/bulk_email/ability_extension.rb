module BulkEmail

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
        ability.can(:send_bulk_emails, resource)
      end

      if resource == Facility.cross_facility && user.billing_administrator?
        ability.can(:send_bulk_emails, resource)
      end
    end

  end

end
