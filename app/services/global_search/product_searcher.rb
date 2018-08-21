# frozen_string_literal: true

module GlobalSearch

  class ProductSearcher < Base

    def template
      "products"
    end

    private

    def search
      name_search.or(description_search)
    end

    def restrict(products)
      facilities = user ? user.operable_facilities.pluck(:id) : []

      products.in_active_facility.not_archived.merge(Product.where(is_hidden: false).or(Product.where(facility: facilities)))
    end

    def name_search
      query_string = "%#{query}%"
      Product.includes(:facility).where("LOWER(products.name) LIKE ?", query_string.downcase)
    end

    def description_search
      query_string = "%#{query}%"
      Product.includes(:facility).where("LOWER(products.description) LIKE ?", query_string.downcase)
    end

  end

end
