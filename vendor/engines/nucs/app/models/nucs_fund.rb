class NucsFund < NucsGe001
  validates_format_of(:value, :with => /^[A-Z0-9]{3,5}$/)
end