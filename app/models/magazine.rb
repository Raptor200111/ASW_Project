class Magazine < ApplicationRecord
  has_many :articles
  has_many :users
end
