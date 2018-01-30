module GlobalSearch

  class ProductSearcher < Base

    def template
      "products"
    end

    private

    def search
      query_string = "%#{query}%"
      Product.where("name like ?", query_string)
    end


  end

end
