class ScishieldTraining < ApplicationRecord
  validates_presence_of :user_id, :course_name
end
