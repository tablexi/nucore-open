# frozen_string_literal: true

module SangerSequencing

  class SubmissionUpdater

    def initialize(submission)
      @submission = submission
    end

    def update_attributes(params)
      @submission.assign_attributes(params)
      mark_unused_samples_for_destruction(params)
      @submission.save
    end

    private

    def mark_unused_samples_for_destruction(params)
      unused_samples(params).each(&:mark_for_destruction)
    end

    def unused_samples(params)
      ids_for_update = params[:samples_attributes].values.map { |a| a[:id].to_s }
      @submission.samples.select { |sample| !ids_for_update.include?(sample.id.to_s) }
    end

  end

end
