class Whitelist

  ALLOWED_CHART_STRINGS=[
    '111-2222222-33333333-01', '123-1234567-12345678-01', '987-9876543-98765432-02'
  ]

  def self.includes?(chart_string)
    ALLOWED_CHART_STRINGS.include? chart_string
  end

end