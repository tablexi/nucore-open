class NucsChartField1 < NucsGe001
  validates_format_of(:value, :with => /^[0-9A-Z]{4,10}$/)
end