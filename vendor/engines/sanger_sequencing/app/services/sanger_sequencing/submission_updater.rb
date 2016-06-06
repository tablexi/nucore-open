module SangerSequencing

  class SubmissionUpdater

    def initialize(submission)
      @submission = submission
    end

    def update_attributes(params)
      @submission.assign_attributes(params)
      mark_unused_samples_for_destruction(params)
      mark_blank_samples_at_end_for_destruction
      @submission.save
    end

    private

    def mark_unused_samples_for_destruction(params)
      unused_samples(params).each(&:mark_for_destruction)
    end

    def mark_blank_samples_at_end_for_destruction
      blank_samples_at_end.each(&:mark_for_destruction)
    end

    def unused_samples(params)
      ids_for_update = params[:samples_attributes].values.map { |a| a[:id].to_s }
      @submission.samples.select { |sample| !ids_for_update.include?(sample.id.to_s) }
    end

    def blank_samples_at_end
      @submission.samples.reverse.each_with_object([]) do |sample, to_delete|
        if sample.customer_sample_id.blank? || sample.marked_for_destruction?
          to_delete << sample
        else
          break to_delete
        end
      end
    end

  end

end
