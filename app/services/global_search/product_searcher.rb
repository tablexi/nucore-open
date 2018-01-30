module GlobalSearch

  class ProductSearcher < Base

    def template
      "products"
    end

    private

    def search
      if NUCore::Database.oracle?
        query_string = ".*#{query}.*"
        Product.where("regexp_like(name, ?, 'i')", query_string)
      else
        query_string = "%#{query}%"
        Product.where("name like ?", query_string)
      end
    end


  end

end
