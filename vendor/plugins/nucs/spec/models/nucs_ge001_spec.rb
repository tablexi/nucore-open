require 'spec_helper'


share_examples_for 'GE001' do

  it { should_not allow_value(mkstr(513)).for(:auxiliary) }
  it { should allow_value(nil).for(:auxiliary) }


  it 'tokenizes. Should raise an error if there is no separator in the source line.' do
    source_line='000To be Eliminated in ConsolidatFNDS_ELIM'
    assert_raises NucsErrors::ImportError do
      described_class.tokenize_source_line(source_line)
    end
  end


  it 'tokenizes. Should return the original source line minus the separator if separator is last char.' do
    source_line='000To be Eliminated in ConsolidatFNDS_ELIM|'
    tokens=described_class.tokenize_source_line(source_line)
    tokens.should be_a_kind_of(Array)
    tokens.size.should == 1
    tokens[0].should == source_line[0...source_line.size-1]
  end


  it 'tokenizes. Should return an Array of size 2 if fed a valid source line.' do
    source_line='000|To be Eliminated in Consolidat|FNDS_ELIM'
    tokens=described_class.tokenize_source_line(source_line)
    tokens.should be_a_kind_of(Array)
    tokens.size.should == 2
    tokens[0].should == source_line[0...source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)]
    tokens[1].should == source_line[source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)+1..-1]
  end


  it 'creates. Should make a new record when fed a valid input line.' do
    tokens=described_class.tokenize_source_line(valid_source_line)
    ge=described_class.create_from_source(tokens)
    ge.should be_a_kind_of(described_class)
    ge.should_not be_new_record
    ge.value.should == tokens[0]
    ge.auxiliary.should == tokens[1]
  end


  it 'creates. Should make a new record with nil auxiliary if tokenizing yields 1 token.' do
    source_line=valid_source_line
    source_line=source_line[0..source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)]
    tokens=described_class.tokenize_source_line(source_line)
    ge=described_class.create_from_source(tokens)
    ge.should be_a_kind_of(described_class)
    ge.should_not be_new_record
    ge.value.should == tokens[0]
    ge.auxiliary.should be_nil
  end


  it 'fails to create. Should return an unsaved record when fed an invalid input line.' do
    source_line=valid_source_line
    source_line=source_line[0..source_line.index(NucsSourcedFromFile::NUCS_TOKEN_SEPARATOR)] + mkstr(513)
    tokens=described_class.tokenize_source_line(source_line)
    ge=described_class.create_from_source(tokens)
    ge.should be_a_kind_of(described_class)
    ge.should be_new_record
  end


  def valid_source_line
    source_line='00011|To be Eliminated in Consolidat|FNDS_ELIM'
    source_line='23' + source_line if described_class == NucsDepartment
    return source_line
  end

end


{ NucsAccount => [5, 10], NucsProgram => [4, 5] }.each do |k, v|
  describe k do
    min, max=v[0], v[1]
    it_should_behave_like 'GE001'
    it { should_not allow_value(mkstr(min, 'a')).for(:value) }
    it { should_not allow_value(mkstr(min, 'A')).for(:value) }
    it { should_not allow_value(mkstr(min-1)).for(:value) }
    it { should_not allow_value(mkstr(max+1)).for(:value) }
    it { should allow_value(mkstr(min)).for(:value) }
  end
end


{ NucsFund => [3, 5], NucsChartField1 => [4, 10], NucsDepartment => [7, 10] }.each do |k, v|
  describe k do
    min, max=v[0], v[1]
    it_should_behave_like 'GE001'
    it { should_not allow_value(mkstr(min, 'a')).for(:value) }
    it { should_not allow_value(mkstr(min-1)).for(:value) }
    it { should_not allow_value(mkstr(max+1)).for(:value) }
    it { should allow_value(mkstr(min)).for(:value) }
    it { should allow_value(mkstr(min, 'A')).for(:value) }
    it { should allow_value(mkstr((min/2.0).ceil, 'A1')).for(:value) }
  end
end

