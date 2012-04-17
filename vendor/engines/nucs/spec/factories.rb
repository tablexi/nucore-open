Factory.define :nucs_grants_budget_tree do |tree|
  tree.account '77599'
  tree.account_desc 'Other Capital Equipment'
  tree.roll_up_node '77501'
  tree.roll_up_node_desc 'Capital Equipment, Restricted'
  tree.parent_node "70000"
  tree.parent_node_desc "Non-Personnel Expenses"
  tree.account_effective_at "2008-12-01"
  tree.tree "NU_GM_BUDGET"
  tree.tree_effective_at "1970-01-01"
end


Factory.define :nucs_gl066_with_dates, :class => NucsGl066 do |gl|
  gl.budget_period '-'
  gl.fund '610'
  gl.department '4735000'
  gl.project '60028213'
  gl.activity '01'
  gl.account '78700'
  gl.starts_at '2010-09-01'
  gl.expires_at '2011-08-31'
end


Factory.define :nucs_gl066_without_dates, :parent => :nucs_gl066_with_dates do |gl|
  gl.budget_period '2010'
  gl.starts_at nil
  gl.expires_at nil
end


Factory.define :nucs_fund do |fund|
  fund.value '171'
  fund.auxiliary 'Designated|DESIGNATED'
end


Factory.define :nucs_account do |acct|
  acct.value '75340'
  acct.auxiliary 'Laboratory Services|LAB SERVIC'
end


Factory.define :nucs_department do |dept|
  dept.value '5308000'
  dept.auxiliary 'A|Gastroenterology|GASTRO||'
end


Factory.define :nucs_program do |dept|
  dept.value '1059'
  dept.auxiliary 'CV Research Fellowship|CV FW'
end


Factory.define :nucs_chart_field1 do |dept|
  dept.value '1093'
  dept.auxiliary 'Fastbreak Friday|FASTBREAK'
end


Factory.define :nucs_project_activity do |pa|
  pa.project '10006346'
  pa.activity '01'
  pa.auxiliary 'Dr. Khazaie Pi Account|01-JAN-01|31-AUG-49|'
end
