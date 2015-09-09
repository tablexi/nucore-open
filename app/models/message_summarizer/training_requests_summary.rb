class MessageSummarizer::TrainingRequestsSummary < MessageSummarizer::FacilityMessageSummary
  private

  def allowed?
    ability.can?(:manage, TrainingRequest)
  end

  def get_count
    facility.training_requests.count
  end

  def i18n_key
    "message_summarizer.training_requests"
  end

  def path
    controller.facility_training_requests_path(facility)
  end
end
