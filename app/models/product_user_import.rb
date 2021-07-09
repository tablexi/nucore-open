# frozen_string_literal: true

require "csv"

class ProductUserImport < ApplicationRecord

  include DownloadableFile

  belongs_to :product
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  validates_presence_of :file, :creator

  attr_accessor :successes, :failures, :skipped

  def process_upload!
    self.successes = []
    self.skipped = []
    self.failures = []
    ProductUser.transaction do
      begin
        CSV.parse(Paperclip.io_adapters.for(file).read, headers: true, skip_lines: /^,*$/).each do |row|
          import_row(row)
        end
      end

      raise ActiveRecord::Rollback if failed?
    end

    self.processed_at = Time.zone.now
    save!

    if succeeded?
      successes.map! do |product_user|
        LogEvent.log(product_user, :create, creator)
        "* #{product_user.user.username}\n"
      end
    end
  end

  def processed?
    processed_at.present?
  end

  def failed?
    failures.count > 0
  end

  def succeeded?
    !failed?
  end

  private

  def import_row(row)
    row_username = row["Username"]
    user = User.find_by(username: row_username)
    new_product_user = ProductUserCreator.create(user: user, product: product, approver: creator)

    if new_product_user.persisted?
      successes << new_product_user
    elsif new_product_user.errors.full_messages.to_sentence == "User is already approved"
      skipped << "* #{row_username}\n"
    else
      failures << "* #{row_username}: #{new_product_user.errors.full_messages.to_sentence}\n\n"
    end
  rescue => e
    failures << "* #{row_username}: #{e.message}\n\n"
  end

  def upload_file_path
    @upload_file_path ||= upload_file.file.path
  end

end
