# frozen_string_literal: true

class ScishieldTraining < ApplicationRecord
  validates_presence_of :user_id, :course_name
end
