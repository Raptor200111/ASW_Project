class Article < ApplicationRecord
  #  belongs_to :user, class_name: 'User', optional: true
  #has_many :comments, class_name: 'Comment', optional: true
  #belongs_to  :magazine, class_name: 'Magazine', optional: true
  validates :body, length: { minimum: 4 , maximum:280 }
end
