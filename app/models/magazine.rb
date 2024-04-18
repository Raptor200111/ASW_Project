class Magazine < ApplicationRecord
  has_many :articles
  has_many :subscriptions
  has_many :subscribers, through: :subscriptions, source: :user
end
