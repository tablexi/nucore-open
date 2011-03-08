class ServiceSurvey < ActiveRecord::Base
  belongs_to              :service
  belongs_to              :survey
  validates_presence_of   :service_id, :survey_id
  
  named_scope             :active, :conditions => {:active => 1}
  named_scope             :inactive, :conditions => {:active => 0}

  def active!
    # disable all other active service surveys
    service.service_surveys.active.each do |ss|
      next if ss.survey_id == self.survey_id
      ss.inactive!
    end
    self.active    = true
    self.active_at = Time.now
    self.save
  end

  def inactive!
    self.update_attribute(:active, false)
  end

  def find_or_create_preview_response_set
    response_set = ResponseSet.find_by_access_code_and_survey_id(self.preview_code, self.survey_id)
    if response_set.blank?
      # create response set and cache access code
      response_set = ResponseSet.create(:survey_id => self.survey_id)
      self.update_attribute(:preview_code, response_set.access_code)
    end
    response_set
  end
end