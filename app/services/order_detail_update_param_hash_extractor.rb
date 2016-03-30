class OrderDetailUpdateParamHashExtractor

  attr_reader :params

  def initialize(params)
    @params = params
  end

  # This extracts and transforms a hash (like controller params) into the form
  # of a hash that Order#update_details expects.
  #
  # For example, if given controller params like this:
  #   { "quantity123" => 2, "note123" => "Noted" }
  # …the #to_h method would return:
  #   { 123 => { quantity: 2, note: "Noted" } }
  def to_h
    params.each_with_object({}) do |(key, value), memo|
      match = key.match(/\A(note|quantity)(\d+)\z/) || next
      property = match[1].to_sym
      id = match[2].to_i
      next if property == :note && !value

      (memo[id] ||= {})[property] = value
    end
  end

end
