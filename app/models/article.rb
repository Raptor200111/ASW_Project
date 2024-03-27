class Article < ApplicationRecord
  validates :author, length: { minimum: 4 }
  validates :body, length: { minimum: 4 , maximum:280 }
end
