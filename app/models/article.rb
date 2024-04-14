class Article < ApplicationRecord
 #  belongs_to :user, class_name: 'User', optional: true
  belongs_to :magazine
  #has_many :comments, class_name: 'Comment', optional: true
  has_many :comments
  #belongs_to  :magazine, class_name: 'Magazine', optional: true
  validates :body, length: { minimum: 4 , maximum:280 }
  validates :url, presence: true, if: :url_required?
  # Method to determine if URL is required based on article type
  def url_required?
    article_type == 'link'
  end
end
