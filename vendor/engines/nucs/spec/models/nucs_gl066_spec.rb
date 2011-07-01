require 'spec_helper'

describe NucsGl066 do

  { :fund => [3, 5], :department => [7, 10] }.each do |k, v|
    min, max=v[0], v[1]
    it { should_not allow_value(mkstr(min-1)).for(k) }
    it { should_not allow_value(mkstr(max+1)).for(k) }
    it { should_not allow_value(mkstr(min, 'a')).for(k) }
    it { should_not allow_value('-').for(k) }
    it { should allow_value(mkstr(min)).for(k) }
    it { should allow_value(mkstr(min, 'B')).for(k) }
    it { should allow_value(mkstr((min/2.0).ceil, 'A1')).for(k) }
  end


  { :budget_period => [4, 8], :project => [8, 15], :activity => [2, 15], :account => [5, 10] }.each do |k, v|
    min, max=v[0], v[1]
    it { should_not allow_value('^').for(k) }
    it { should_not allow_value(mkstr(min-1)).for(k) }
    it { should_not allow_value(mkstr(max+1)).for(k) }
    it { should_not allow_value(mkstr(min, 'a')).for(k) }
    it { should allow_value('-').for(k) }
    it { should allow_value(mkstr(min)).for(k) }
  end


  [ :starts_at, :expires_at ].each do |method|
    it { should have_db_column(method).of_type(:datetime) }
    it { should allow_value(nil).for(method) }
  end


  it "should give a Time based on budget_period even when starts_at column value is null" do
    gl=Factory.create(:nucs_gl066_without_dates)
    date=gl.starts_at
    date.should be_a_kind_of(Time)
    date.should == Time.zone.parse("#{gl.budget_period}0901")-1.year
  end


  it "should give a Time based on starts_at even when expires_at column value is null" do
    gl=Factory.create(:nucs_gl066_without_dates)
    date=gl.expires_at
    date.should be_a_kind_of(Time)
    date.should == (gl.starts_at + 1.year - 1.second)
  end


  it 'should tell us when now is before a starts_at date' do
    gl=Factory.create(:nucs_gl066_with_dates, { :starts_at => Time.zone.now+5.day, :expires_at => Time.zone.now+8.day})
    gl.should be_expired
  end


  it 'should tell us when now is after a expires_at date' do
    gl=Factory.create(:nucs_gl066_with_dates, { :starts_at => Time.zone.now-5.day, :expires_at => Time.zone.now-2.day})
    gl.should be_expired
  end


  it 'should tell us when now is in a starts_at and expires_at window' do
    gl=Factory.create(:nucs_gl066_with_dates, { :starts_at => Time.zone.now-3.day, :expires_at => Time.zone.now+3.day})
    gl.should_not be_expired
  end


  it "should raise an ImportError on malformed source lines" do
    assert_raises NucsErrors::ImportError do
      NucsGl066.tokenize_source_line('-|156|2243550|-|-|-||')
    end
  end


  it "should return an invalid record when creating from a valid source line with invalid data" do
    tokens=NucsGl066.tokenize_source_line('2010|171|4011100|XXXXXXXX|-|-||')
    gl=NucsGl066.create_from_source(tokens)
    gl.should be_new_record
    gl.should_not be_valid
  end


  { '2010|171|4011100|10002342|-|-||' => 6, '-|610|4011400|60023761|01|77000|27-APR-09|26-APR-11' => 8 }.each do |k, v|
    it "should successfully tokenize #{k}" do
      assert_nothing_raised do
        tokens=NucsGl066.tokenize_source_line(k)
        tokens.should be_a_kind_of(Array)
        tokens.size.should == v
      end
    end


    it "should successfully create a new record from #{k}" do
      tokens=NucsGl066.tokenize_source_line(k)
      gl=NucsGl066.create_from_source(tokens)
      gl.should be_a_kind_of(NucsGl066)
      gl.should_not be_new_record

      if tokens.size > 6
        gl.starts_at.should == Time.zone.parse(tokens[6])
        gl.expires_at.should == Time.zone.parse(tokens[7])
      end
    end
  end

end