class Subscription < ApplicationRecord
  belongs_to :magazine
  belongs_to :user
  validates :user_id, uniqueness: { scope: :magazine_id }
end
