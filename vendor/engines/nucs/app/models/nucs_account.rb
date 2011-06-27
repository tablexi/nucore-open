class NucsAccount < NucsGe001
  validates_format_of(:value, :with => /^\d{5,10}$/)
end