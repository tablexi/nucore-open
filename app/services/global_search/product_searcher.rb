module GlobalSearch

  class ProductSearcher < Base

    def template
      "products"
    end

    private

    def search
      query_string = "%#{query}%"
      Product.includes(:facility).where("LOWER(products.name) LIKE ?", query_string.downcase)
    end

    def restrict(products)
      facilities = user ? user.operable_facilities : []
      products.in_active_facility.not_archived.select { |product| product.visible? || facilities.include?(product.facility) }
      # TODO: Try this (or something like it) in Rails 5
      # products.in_active_facility.not_archived.merge(Product.where(hidden: false).or(Product.where(facility: facilities)))
    end

  end

end
