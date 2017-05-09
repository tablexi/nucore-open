module SecureRooms

  module LinkCollectionExtension

    extend ActiveSupport::Concern

    included do
      insert_index = tab_methods.index(:admin_products) || -1
      tab_methods.insert(insert_index, :admin_occupancies)
    end

    def admin_occupancies
      if single_facility? && SecureRoom.for_facility(facility).exists?
        NavTab::Link.new(
          tab: :admin_occupancies,
          url: facility_occupancies_path(facility),
        )
      end
    end

  end

end
