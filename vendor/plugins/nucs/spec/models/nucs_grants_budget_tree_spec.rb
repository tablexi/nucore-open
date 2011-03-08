require 'spec_helper'

describe NucsGrantsBudgetTree do

  { :account => [5, 10], :roll_up_node => [5, 20], :parent_node => [5, 20] }.each do |k, v|
    min, max=v[0], v[1]
    it { should_not allow_value(nil).for(k) }
    it { should_not allow_value(mkstr(min-1)).for(k) }
    it { should_not allow_value(mkstr(max+1)).for(k) }
    it { should_not allow_value(mkstr(min, 'a')).for(k) }
    it { should allow_value(mkstr(min)).for(k) }
  end


  { :account_desc => 30, :roll_up_node_desc => 30, :parent_node_desc => 30, :tree => 18 }.each do |k, v|
    it { should_not allow_value(nil).for(k) }
    it { should ensure_length_of(k).is_at_most(v) }
  end


  [ :account_effective_at, :tree_effective_at ].each do |method|
    it { should have_db_column(method).of_type(:datetime) }
    it { should_not allow_value(nil).for(method) }
  end


  it "should return an invalid record from a invalid source line" do
    source_line='XXXX|Furniture-Capital|77501|Capital Equipment, Restricted|70000|Non-Personnel Expenses|1901-01-01|NU_GM_BUDGET|1901-01-01'
    tokens=NucsGrantsBudgetTree.tokenize_source_line(source_line)
    tree=NucsGrantsBudgetTree.create_from_source(tokens)
    tree.should be_new_record
    tree.should_not be_valid
  end


  it "should create a new record from a valid source line" do
    source_line='77510|Furniture-Capital|77501|Capital Equipment, Restricted|70000|Non-Personnel Expenses|1901-01-01|NU_GM_BUDGET|1901-01-01'
    tokens=NucsGrantsBudgetTree.tokenize_source_line(source_line)
    tree=NucsGrantsBudgetTree.create_from_source(tokens)
    tree.should be_a_kind_of(NucsGrantsBudgetTree)
    tree.should_not be_new_record

    methods=[
      :account, :account_desc, :roll_up_node, :roll_up_node_desc, :parent_node,
      :parent_node_desc, :account_effective_at, :tree, :tree_effective_at
    ]

    methods.each_with_index do |method, ndx|
      token=tokens[ndx]
      ret=tree.method(method).call
      token=Time.zone.parse(token) if ret.is_a?(Time)
      token.should == ret
    end
  end

end