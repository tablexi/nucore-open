class Service < Product
  has_many :service_price_policies
  has_many :price_policies, :foreign_key => 'service_id'
  has_many :service_surveys, :after_remove => :after_remove_ss_callback
  has_many :surveys, :through => :service_surveys
  has_one  :active_survey, :through => :service_surveys, :conditions => ["service_surveys.active = 1"], :source => :survey

  validates_presence_of :initial_order_status_id, :facility_account_id
  validates_numericality_of :account, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 99999


  def cheapest_price_policy (groups = [])
    return nil if groups.empty?

    min = nil
    cheapest_total = 0
    current_price_policies.each do |pp|
      if !pp.expired? && !pp.restrict_purchase? && groups.include?(pp.price_group)
        costs = pp.calculate_cost_and_subsidy
        total = costs[:cost] - costs[:subsidy]
        if min.nil? || total < cheapest_total
          cheapest_total = total
          min = pp
        end
      end
    end
    min
  end

  # returns true if there is at least 1 active survey; false otherwise
  def active_survey?
    !self.active_survey.blank?
  end
  
  # import the survey with the specified filepath
  def import_survey(filepath)
    raise Exception, "invalid file" if !File.exists?(filepath)

    # call surveyor rake task to import survey
    raise Exception, "An error was encountered while processing the DSL file" unless system "#{RAKE_PATH}rake surveyor:import FILE=#{filepath} RAILS_ENV=#{Rails.env} --trace 2>&1 >> #{Rails.root}/log/surveyor_rake.log"

    # LEAVE THIS CODE; useful for debugging surveyor issues on production and staging
    #logger.fatal('TK TK TK')
    #logger.fatal("COMMAND: #{RAKE_PATH}rake surveyor:import FILE=#{filepath} RAILS_ENV=#{Rails.env} --trace 2>&1 >> #{Rails.root}/log/surveyor_rake.log")
    #logger.fatal(`#{RAKE_PATH}rake surveyor:import FILE=#{filepath} RAILS_ENV=#{Rails.env} --trace 2>&1 >> #{Rails.root}/log/surveyor_rake.log`)
    #raise Exception, 'DIE DIE DIE'


    # find new survey
    survey = Survey.last
    
    # survey can only be 1 section
    if survey.sections.count > 1
      survey.destroy
      raise Exception, "Surveys with multiple sections are not allowed"
    end

    # attach survey to service
    self.surveys.push(survey)

    # return survey
    survey
  end

  def can_purchase? (group_ids = nil)
    return false if is_archived? || !facility.is_active?
    if group_ids.nil?
      current_price_policies.empty? || current_price_policies.any?{|pp| !pp.expired? && !pp.restrict_purchase?}
    elsif group_ids.empty?
      false
    else
      current_price_policies.empty? || current_price_policies.any?{|pp| !pp.expired? && !pp.restrict_purchase? && group_ids.include?(pp.price_group_id)}
    end
  end
  protected
  
  def after_remove_ss_callback(o)
    # remove survey
    o.survey.destroy rescue nil
  end
end
