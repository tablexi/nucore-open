module NucsValidatorHelper
  #
  # Seeds the DB with a GL066 record for validation of +chart_string+
  # [_chart_string_]
  #   A +ValidatorFactory#pattern+ matching +String+
  # [_attrs_]
  #   Overrides for the +NucsGl066+ Factory, if any
  def define_gl066(chart_string, attrs={})
    components=chart_string.match(NucsValidator.pattern)
    attrs.merge!(:fund => components[1]) unless attrs.has_key?(:fund)
    attrs.merge!(:department => components[2]) unless attrs.has_key?(:department)
    attrs.merge!(:project => components[3]) if components[3] and not attrs.has_key?(:project)
    attrs.merge!(:activity => components[4]) if components[4] and not attrs.has_key?(:activity)

    if attrs.has_key?(:expires_at) or attrs.has_key?(:starts_at)
      Factory.create(:nucs_gl066_with_dates, attrs)
    else
      unless attrs.has_key?(:budget_period)
        today=Time.zone.today
        period=(today+1.year).year
        period=today.year if Time.zone.parse("#{period}0901")-1.year > today
        attrs.merge!(:budget_period => period)
      end

      gl=Factory.create(:nucs_gl066_without_dates, attrs)
    end

    Factory.create(:nucs_chart_field1, :value => components[6]) if components[6]
  end


  #
  # Seeds the DB with GE001 records for validation of +chart_string+
  # [_chart_string_]
  #   A +ValidatorFactory#pattern+ matching +String+
  def define_ge001(chart_string)
    components=chart_string.match(NucsValidator.pattern)
    Factory.create(:nucs_fund, :value => components[1])
    Factory.create(:nucs_department, :value => components[2])

    if components[3]
      project_activity={ :project => components[3] }
      project_activity.merge!(:activity => components[4]) if components[4]
      Factory.create(:nucs_project_activity, project_activity)
    end

    Factory.create(:nucs_program, :value => components[5]) if components[5]
    Factory.create(:nucs_chart_field1, :value => components[6]) if components[6]
  end


  #
  # Seeds the DB so that +account+ is open for +chart_string+
  # [_account_]
  #   A chart string account component
  # [_chart_string_]
  #   A +ValidatorFactory#pattern+ matching +String+
  # [_budget_tree_attrs_]
  #   Overrides for the +NucsGrantsBudgetTree+ Factory, if any
  # [_gl066_attrs_]
  #   Overrides for the +NucsGl066+ Factory, if any
  def define_open_account(account, chart_string, budget_tree_attrs={}, gl066_attrs={})
    tree=Factory.create(:nucs_grants_budget_tree, budget_tree_attrs.merge(:account => account))
    define_ge001(chart_string)
    define_gl066(chart_string, gl066_attrs.merge(:account => tree.roll_up_node))
  end

end