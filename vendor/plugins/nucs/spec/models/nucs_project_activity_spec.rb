require 'spec_helper'


describe NucsProjectActivity do

  { :project => [8, 15], :activity => [2, 15] }.each do |k, v|
    min, max=v[0], v[1]
    it { should_not allow_value(mkstr(min, 'a')).for(k) }
    it { should_not allow_value(mkstr(min, 'A')).for(k) }
    it { should_not allow_value(mkstr(min-1)).for(k) }
    it { should_not allow_value(mkstr(max+1)).for(k) }
    it { should allow_value(mkstr(min)).for(k) }
  end


  it 'tokenizes. Should return an Array of size 3 on a valid, full line' do
    source_line='40000137|01|Sundry Persons for CAS & Sch o|31-DEC-23|31-AUG-49|'
    tokens=NucsProjectActivity.tokenize_source_line(source_line)
    tokens.should be_a_kind_of(Array)
    tokens.size.should == 3
    sep_ndx=source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)
    tokens[0].should == source_line[0...sep_ndx]
    nxt_sep_ndx=source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR, sep_ndx+1)
    tokens[1].should == source_line[sep_ndx+1...nxt_sep_ndx]
    tokens[2].should == source_line[nxt_sep_ndx+1..-1]
  end


  it 'tokenizes. Should return an Array of size 2 if no auxiliary data is present' do
    source_line='40000137|01|'
    tokens=NucsProjectActivity.tokenize_source_line(source_line)
    tokens.should be_a_kind_of(Array)
    tokens.size.should == 2
    sep_ndx=source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)
    tokens[0].should == source_line[0...sep_ndx]
    nxt_sep_ndx=source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR, sep_ndx+1)
    tokens[1].should == source_line[sep_ndx+1...nxt_sep_ndx]
  end


  [ '4000013701Sundry Persons for CAS & Sch o31-DEC-2331-AUG-49',
    '4000013701Sundry Persons for CAS & Sch o31-DEC-2331-AUG-49|',
    '40000137|01Sundry Persons for CAS & Sch o31-DEC-2331-AUG-49' ].each do |line|

    it "tokenizes. Should raise an error on #{line}" do
      assert_raises NucsErrors::ImportError do
        NucsProjectActivity.tokenize_source_line(line)
      end
    end
  end


  it 'creates. Should make a new record on line with no auxiliary data' do
    source_line='40000137|01|'
    tokens=NucsProjectActivity.tokenize_source_line(source_line)
    pa=NucsProjectActivity.create_from_source(tokens)
    pa.should be_a_kind_of(NucsProjectActivity)
    pa.should_not be_new_record
    pa.project.should == tokens[0]
    pa.activity.should == tokens[1]
  end


  it 'creates. Should make a new record on line with auxiliary data' do
    source_line='40000137|01|Sundry Persons for CAS & Sch o|31-DEC-23|31-AUG-49|'
    tokens=NucsProjectActivity.tokenize_source_line(source_line)
    pa=NucsProjectActivity.create_from_source(tokens)
    pa.should be_a_kind_of(NucsProjectActivity)
    pa.should_not be_new_record
    pa.project.should == tokens[0]
    pa.activity.should == tokens[1]
    pa.auxiliary.should == tokens[2]
  end


  it 'fails to creates. Should return an invalid object on a valid line with invalid data' do
    source_line='XXXXXXX|01|'
    tokens=NucsProjectActivity.tokenize_source_line(source_line)
    pa=NucsProjectActivity.create_from_source(tokens)
    pa.should be_a_kind_of(NucsProjectActivity)
    pa.should be_new_record
  end

end