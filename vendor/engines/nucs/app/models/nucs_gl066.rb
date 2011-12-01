class NucsGl066 < ActiveRecord::Base
  include NucsSourcedFromFile

  validates_format_of(:budget_period, :with => /^(-|\d{4,8})$/)
  validates_format_of(:fund, :with => /^[A-Z0-9]{3,5}$/)
  validates_format_of(:department, :with => /^[A-Z0-9]{7,10}$/)
  validates_format_of(:project, :with => /^(-|\d{8,15})$/)
  validates_format_of(:activity, :with => /^(-|\d{2,15})$/)
  validates_format_of(:account, :with => /^(-|\d{5,10})$/)


  #
  # If no date was specified during import one will be calculated
  # on the fly from +@budget_period+ if the attribute exists
  def starts_at
    return (self[:starts_at].nil? && !budget_period.nil?) ? (Time.zone.parse("#{budget_period}0901")-1.year) : self[:starts_at]
  end


  #
  # If no date was specified during import one will be calculated
  # on the fly from +@starts_at+ if the attribute exists
  def expires_at
    return (self[:expires_at].nil? && !starts_at.nil?) ? starts_at + 1.year - 1.second : self[:expires_at]
  end


  #
  # Returns false if the current time is between or on +#starts_at+ and
  # +#expires_at+. true otherwise.
  def expired?
    today=Time.zone.now.to_datetime.to_date
    return expires_at.to_date < today  || starts_at.to_date > today
  end


  def self.tokenize_source_line(source_line)
    raise ImportError.new if source_line !~ /^\d{4,4}\||\d{2,2}-[A-Z]{3,3}-\d{2,2}\|\d{2,2}-[A-Z]{3,3}-\d{2,2}$/
    return source_line.split(NUCS_TOKEN_SEPARATOR)
  end


  def self.create_from_source(tokens)
    attrs={
      :budget_period => tokens[0],
      :fund => tokens[1],
      :department => tokens[2],
      :project => tokens[3],
      :activity => tokens[4],
      :account => tokens[5]
    }

    if tokens.size > 6
      # has start and expire dates
      attrs[:starts_at]=Time.zone.parse(tokens[6])
      attrs[:expires_at]=Time.zone.parse(tokens[7])
    end

    create(attrs)
  end

end