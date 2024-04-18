class VoteComment < ApplicationRecord
  belongs_to :user
  belongs_to :comment
  validates :user_id, uniqueness: {scope: :comment_id, message: "has already voted for this comment"}
  validates :value, inclusion: {in: %w(up down), message: "%{value} is not a valid vote"}
end
