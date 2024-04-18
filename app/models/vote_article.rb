class VoteArticle < ApplicationRecord
  belongs_to :user
  belongs_to :article
  validates :user_id, uniqueness: { scope: :article_id, message: "has already voted for this article" }
  validates :value, inclusion: { in: %w(up down), message: "%{value} is not a valid vote" }
end
