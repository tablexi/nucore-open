module BulkEmail

  module UserExtension

    extend ActiveSupport::Concern

    included do
      has_many :bulk_email_jobs,
               class_name: "BulkEmail::Job",
               foreign_key: :user_id,
               inverse_of: :user,
               dependent: :destroy # Though in practice Users are not destroyed
    end

  end

end
