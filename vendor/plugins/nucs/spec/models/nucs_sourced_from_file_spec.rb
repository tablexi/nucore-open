require 'spec_helper'


describe NucsGrantsBudgetTree do

  it 'should delete all records in the DB and successfully ingest a source file' do
    source=File.join(Rails.root, 'spec', 'files', 'grants_budget_tree.txt')
    gbt=Factory.create(:nucs_grants_budget_tree)
    NucsGrantsBudgetTree.source(source)
    NucsGrantsBudgetTree.count.should == 6
    assert !NucsGrantsBudgetTree.exists?(gbt.id)
  end

end