module TransactionSearch

  class ProductSearcher < BaseSearcher

    def options
      Product.where(id: order_details.select("distinct order_details.product_id")).order(:name)
    end

    def search(params)
      order_details.for_products(params)
    end

    def optimized
      order_details.includes(:product)
    end

    def data_attrs(product)
      {
        facility: product.facility_id,
        restricted: product.requires_approval?,
        product_type: product.type.downcase,
      }
    end

  end

end
