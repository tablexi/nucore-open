class NucsValidator
  include NucsErrors

  NUCS_BLANK='-'
  NUCS_PATTERN=/^(\d{3})-(\d{7})(?:-(\d{8}))?(?:-(\d{2}))?(?:-(\d{4}))?(?:-(\d{4}))?$/

  attr_reader :chart_string, :fund, :department, :project, :activity, :program, :chart_field1, :account


  #
  # [_chart_string_]
  #   A string that matches +NUCS_PATTERN+. Doesn't include +account+.
  # [_account_]
  #   The account component of a NU chart string
  def initialize(chart_string, account=nil)
    super()
    self.account=account if account
    self.chart_string=chart_string
  end


  #
  # Raises a +NucsErrors::InputError+ if +account+ is not a string of 5 digits
  def account=(account)
    account=account.to_s
    raise InputError.new('account', account) if account !~ /^\d{5}$/
    raise BlacklistedError.new('account', account) unless Blacklist.valid_account?(account)
    @account=account
  end


  #
  # Raises a +NucsErrors::InputError+ if +chart_string+ doesn't match +NUCS_PATTERN+
  def chart_string=(chart_string)
    raise InputError.new('chart string', chart_string) unless valid_chart_string?(chart_string)
    @chart_string=chart_string
    parse_chart_string
    raise BlacklistedError.new('fund', @fund) unless Blacklist.valid_fund?(@fund)
  end


  #
  # Performs a full NU v9 chart string validation. Returns nil and raises
  # no +Exception+ if this object's +#account+ accepts payment for the
  # components in +#chart_string+. Otherwise one of the +NucsErrors+
  # will be raised.
  #
  # You must have set +@account+ before calling this method!
  def account_is_open!
    raise NucsErrors::InputError.new('account', nil) unless @account
    return validate_zero_fund! if @fund.start_with?('0')
    return validate_ge001_components! if revenue_account?
    validate_chart_field1!
    components=validate_gl066_components!

    if grant?
      tree=NucsGrantsBudgetTree.find_by_account(@account)
      raise UnknownBudgetTreeError.new(@account) unless tree
      validate_gl066_components!(tree.roll_up_node)
    end

    validate_gl066_PAD_components!(components)
  end


  #
  # Compares this object's +#chart string+ components against
  # known values in the DB.
  # [_return_]
  #   true if all known components are found, false otherwise
  def components_exist?
    begin
      validate_ge001_components!
    rescue NucsError
      return false
    end

    return true
  end


  #
  # Use +#chart_string+ to search the GL066 table for rows with
  # all components. All given components must be present, no more,
  # no less. If today's date falls within the starts_at and expires_at
  # window return the latest value of expires_at that is found.
  # return nil otherwise.
  def latest_expiration
    where={
      :fund => @fund,
      :department => @department,
    }

    where.merge!(:project => @project) if @project
    where.merge!(:activity => @activity) if @activity
    gls=NucsGl066.find(:all, :conditions => where)
    gls.delete_if {|gl| (@project.nil? && gl.project && gl.project != NUCS_BLANK) or (@activity.nil? && gl.activity && gl.activity != NUCS_BLANK) }

    latest_date=nil

    gls.each do |gl|
      next if gl.expired?
      latest_date=gl.expires_at if latest_date.nil? or gl.expires_at > latest_date
    end

    return latest_date
  end


  private

  def parse_chart_string
    results=@chart_string.match(NUCS_PATTERN)
    @fund=results[1]
    @department=results[2]
    @project=results[3]
    @activity=results[4]
    @program=results[5]
    @chart_field1=results[6]
  end


  def revenue_account?
    return !(@account !~ /^(4|5)/)
  end


  def grant?
    return @project && @project.start_with?('6')
  end


  def valid_chart_string?(chart_string)
    return !(chart_string !~ NUCS_PATTERN)
  end


  def validate_zero_fund!
    return validate_ge001_components! if @fund =~ /^02\d$/
    raise TranspositionError.new('011', '110') if @fund == '011'
    raise InputError.new('fund', @fund)
  end


  def validate_chart_field1!
    raise UnknownGE001Error.new('chart field 1', @chart_field1) if @chart_field1 && NucsChartField1.find_by_value(@chart_field1).nil?
  end


  def validate_ge001_components!
    raise UnknownGE001Error.new('fund', @fund) unless NucsFund.find_by_value(@fund)
    raise UnknownGE001Error.new('department', @department) unless NucsDepartment.find_by_value(@department)
    raise UnknownGE001Error.new('project', @project) if @project && NucsProjectActivity.find_by_project(@project).nil?
    raise UnknownGE001Error.new('activity', @activity) if @activity && NucsProjectActivity.find_by_activity(@activity).nil?
    raise UnknownGE001Error.new('program', @program) if @program && NucsProgram.find_by_value(@program).nil?
    validate_chart_field1!
  end


  def validate_gl066_components!(account=nil)
    where={ :fund => @fund, :department => @department }
    where.merge!(:account => account) if account
    gls=NucsGl066.find(:all, :conditions => where)
    raise UnknownGL066Error.new(where) if gls.empty?
    return gls
  end

  #
  # Validate Project, Activity, and date components
  def validate_gl066_PAD_components!(gls)
    if @project
      # This logic breaks from the NU v9 rules in order to address Task #32369
      raise InputError.new('activity', nil) unless @activity
      raise UnknownGL066Error.new('activity', @activity) if grant? && !gls.any?{|gl| gl.activity == @activity }
      raise UnknownGL066Error.new('activity', @activity) if @fund.to_i < 800 && @activity != '01'
    end

    raise UnknownGL066Error.new('project', @project) unless @project.nil? or gls.any?{|gl| gl.project == @project }
    raise DatedGL066Error.new unless gls.any?{|gl| !gl.expired? }
  end

end