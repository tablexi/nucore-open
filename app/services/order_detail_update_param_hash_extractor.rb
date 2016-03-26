class OrderDetailUpdateParamHashExtractor

  attr_reader :params

  def initialize(params)
    @params = params
  end

  def updates_as_hash
    params.each_with_object({}) do |(key, value), memo|
      match = key.match(/\A(note|quantity)(\d+)\z/) || next
      property = match[1].to_sym
      id = match[2].to_i
      next if property == :note && !value

      (memo[id] ||= {})[property] = value
    end
  end

end
