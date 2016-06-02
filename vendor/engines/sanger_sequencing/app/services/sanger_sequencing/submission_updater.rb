module SangerSequencing

  class SubmissionUpdater

    def initialize(submission)
      @submission = submission
    end

    def update_attributes(params)
      @submission.assign_attributes(params)
      mark_blank_samples_at_end_for_destruction
      @submission.save
    end

    private

    def mark_blank_samples_at_end_for_destruction
      blank_samples_at_end.each(&:mark_for_destruction)
    end

    def blank_samples_at_end
      @submission.samples.reverse.each_with_object([]) do |sample, to_delete|
        if sample.customer_sample_id?
          break to_delete
        else
          to_delete << sample
        end
      end
    end

  end

end
