module TransactionSearch

  class BaseSearcher

    attr_reader :order_details

    def self.key
      to_s.demodulize.sub(/Searcher\z/, '').pluralize.underscore
    end

    # If given a class, return the class, otherwise treat it as a string and
    # try to find the searcher class
    def self.from(key_or_class)
      case key_or_class
      when Class
        key_or_class
      else
        "TransactionSearch::#{key_or_class.to_s.camelize.singularize}Searcher".constantize
      end
    end

    def initialize(order_details)
      @order_details = order_details
    end

    def key
      self.class.key
    end

    def multipart?
      false
    end

    def label_method
      nil
    end

    def label
      nil
    end

    def options
      raise NotImplementedError
    end

    def search(_params)
      raise NotImplementedError
    end

    # Include any optimizations to `order_details` such as `includes` or `preload`
    def optimized
      order_details
    end

  end

end
