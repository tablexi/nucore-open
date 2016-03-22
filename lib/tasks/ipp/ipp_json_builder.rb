#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppJsonBuilder

  def build_json_file(order_details)
    json = []
    wanted_attrs = [:id, :actual_cost, :actual_subsidy, :estimated_cost, :estimated_subsidy]
    order_details.each { |od| json << od.to_json(only: wanted_attrs, root: false) }
    File.write "order_details.json", json.join("\n")
  end

  def parse_json_file(filename)
    parsed = {}

    File.readlines(filename).each do |line|
      attrs = JSON.parse line
      parsed[attrs.delete("id")] = attrs
    end

    parsed
  end

end
