class NucsProgram < NucsGe001
  validates_format_of(:value, :with => /^\d{4,5}$/)
end