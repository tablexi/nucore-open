class Blacklist

  DISALLOWED_FUNDS=[
    '010', '011', '012', '013', '014', '020', '021',
    '022', '023', '024', '025', '026', '030', '120',
    '130', '131', '132', '133', '330', '410', '420',
    '430', '431', '432', '433', '460', '470', '471',
    '472', '480', '481', '482', '483', '510', '520',
    '530', '540', '830', '840'
  ]


  def self.valid_fund?(fund)
    !DISALLOWED_FUNDS.include?(fund) && fund.to_i > 100
  end


  def self.valid_account?(acct)
    acct =~ /^(5|7)/
  end

end