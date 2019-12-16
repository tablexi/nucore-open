# frozen_string_literal: true

module SecureRooms

  module AccessRules

    class RequiresResearchSafetyCertificationsRule < SecureRooms::AccessRules::BaseRule

      def evaluate
        deny!(:insufficient_research_safety) unless certified?
      end

      private

      def certified?
        secure_room.research_safety_certificates.all? do |certificate|
          ResearchSafetyCertificationLookup.certified?(user, certificate)
        end
      end

    end

  end

end
