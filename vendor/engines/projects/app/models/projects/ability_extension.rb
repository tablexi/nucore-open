# frozen_string_literal: true

module Projects

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if resource.is_a?(Facility)
        if user.operator_of?(resource) && !user.facility_billing_administrator_of?(resource)
          ability.can([:create, :index, :new], Projects::Project)
        end

        if user.facility_staff_or_manager_of?(resource) || user.facility_director_of?(resource)
          ability.can :cross_core_orders, Projects::Project
        end
      elsif resource.is_a?(Project)
        ability.can [:show, :edit, :update], Projects::Project do |project|
          facility_ids = project.orders&.map(&:facility_id)&.uniq

          facility_ids.present? && facility_ids.any? { |facility_id| user.facility_staff_or_manager_of?(Facility.find(facility_id)) }
        end
      end
    end

  end

end
