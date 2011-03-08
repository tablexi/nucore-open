class NucsGrantsBudgetTree < ActiveRecord::Base
  include NucsSourcedFromFile

  validates_format_of(:account, :with => /^\d{5,10}$/)
  validates_length_of(:account_desc, :maximum => 30)
  validates_format_of(:roll_up_node, :with => /^\d{5,20}$/)
  validates_length_of(:roll_up_node_desc, :maximum => 30)
  validates_format_of(:parent_node, :with => /^\d{5,20}$/)
  validates_length_of(:parent_node_desc, :maximum => 30)
  validates_length_of(:tree, :maximum => 18)
  validates_presence_of(:account_effective_at)
  validates_presence_of(:tree_effective_at)


  def self.create_from_source(tokens)
    create({
      :account => tokens[0],
      :account_desc => tokens[1],
      :roll_up_node => tokens[2],
      :roll_up_node_desc => tokens[3],
      :parent_node => tokens[4],
      :parent_node_desc => tokens[5],
      :account_effective_at => Time.zone.parse(tokens[6]),
      :tree => tokens[7],
      :tree_effective_at => Time.zone.parse(tokens[8])
    })
  end

end