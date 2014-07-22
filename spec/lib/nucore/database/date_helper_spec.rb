require 'spec_helper'

module DateHelperSpec
  include NUCore::Database::DateHelper
end

describe NUCore::Database::DateHelper do
  context 'Parsing dates with 2-digit years' do
    def parse_date(date_string)
      DateHelperSpec.parse_2_digit_year_date(date_string).strftime('%Y%m%d')
    end

    it 'should parse strings as 21st century dates' do
      expect(parse_date('1JAN00')).to eq '20000101'
      expect(parse_date('1-JAN-00')).to eq '20000101'
      expect(parse_date('08JUN04')).to eq '20040608'
      expect(parse_date('08-JUN-04')).to eq '20040608'
      expect(parse_date('31DEC14')).to eq '20141231'
      expect(parse_date('31-DEC-14')).to eq '20141231'
      expect(parse_date('31MAR49')).to eq '20490331'
      expect(parse_date('31-MAR-49')).to eq '20490331'
      expect(parse_date('05FEB99')).to eq '20990205'
      expect(parse_date('05-FEB-99')).to eq '20990205'
    end
  end
end
