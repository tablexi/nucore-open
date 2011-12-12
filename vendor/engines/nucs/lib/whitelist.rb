class Whitelist

  ALLOWED_CHART_STRINGS=[
    '111-2222222-33333333-01'
  ]

  def self.includes?(chart_string)
    ALLOWED_CHART_STRINGS.include? chart_string
  end

end