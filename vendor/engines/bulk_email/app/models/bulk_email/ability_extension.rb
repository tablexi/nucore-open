module BulkEmail

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      # TODO: Add specific abilities for Bulk Email
      #
      # The existing ":send_bulk_emails" ability comes as a side-effect of a
      # user having ":manage" abilities on a Facility.
    end

  end

end
