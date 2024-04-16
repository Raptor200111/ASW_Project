class Article < ApplicationRecord
 #  belongs_to :user, class_name: 'User', optional: true
  #has_many :comments, class_name: 'Comment', optional: true
  has_many :comments
  belongs_to :magazine, foreign_key: 'magazine_id'
  #belongs_to  :magazine, class_name: 'Magazine', optional: true
  validates :title, length: {minimum: 1, maximum: 255}
  validates :body, length: { minimum: 0 , maximum:35000 }
  validates :url, presence: true, if: :url_required?
  # Method to determine if URL is required based on article type
  def url_required?
    article_type == 'link'
  end
  def toggle_boost!
    update(boosted: !boosted)
  end
end
