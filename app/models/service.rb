class Service < Product
  has_many :service_price_policies
  has_many :price_policies, :foreign_key => 'service_id'
  has_many :external_service_passers, :as => :passer
  has_many :external_services, :through => :external_service_passers

  validates_presence_of :initial_order_status_id, :facility_account_id


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

  def active_survey
    active=external_service_passers.find(
            :first,
            :joins => 'INNER JOIN external_services ON external_services.id=external_service_id',
            :conditions => [ 'active = 1 AND external_services.type = ?', ExternalServiceManager.survey_service.name ]
    )

    active ? active.external_service : nil
  end

  # returns true if there is at least 1 active survey; false otherwise
  def active_survey?
    !self.active_survey.blank?
  end

  # returns true if there is an active template... false otherwise
  def active_template?
    self.file_uploads.template.count > 0
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

end
