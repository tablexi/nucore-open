module SangerSequencing

  class SampleResultFileSaver

    include ActiveModel::Validations

    FILENAME_FORMAT = /\A(\d+)_.+/

    attr_reader :params, :current_user

    validate :filename_has_sample_id
    validate :has_valid_sample

    def initialize(batch, current_user, params)
      @batch = batch
      @params = params
      @current_user = current_user
    end

    def save
      return false unless valid?
      stored_file = StoredFile.new(file: file, name: filename,
                                   file_type: "sample_result", created_by: current_user.id,
                                   order_detail: sample.submission.order_detail,
                                   product_id: sample.submission.order_detail.product_id)
      stored_file.save
    end

    def filename
      params[:qqfilename].presence || file.original_filename
    end

    def sample
      return @sample if defined?(@sample)
      @sample = @batch.samples.find_by(id: sample_id)
    end

    private

    def has_valid_sample
      return unless filename_has_sample_id?
      errors.add(:sample, :blank, id: sample_id) unless sample
    end

    def filename_has_sample_id
      errors.add(:filename, :invalid) unless filename_has_sample_id?
    end

    def filename_has_sample_id?
      sample_id.present?
    end

    def sample_id
      filename.match(FILENAME_FORMAT).try(:[], 1)
    end

    def file
      params[:qqfile]
    end

  end

end
