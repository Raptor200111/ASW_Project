class Article < ApplicationRecord

  belongs_to :magazine, foreign_key: 'magazine_id'
  #has_many :comments, class_name: 'Comment', optional: true
  has_many :comments
  belongs_to :user
  has_many :boosts
  has_many :boosters, through: :boosts, source: :user
  has_many :vote_articles
  has_many :voters, through: :vote_articles, source: :user
  #belongs_to  :magazine, class_name: 'Magazine', optional: true
  validates :title, length: {minimum: 1, maximum: 255, message: "article surpases title has to have title with maximum of 255 character" }
  validates :body, length: { maximum:35000, message: "article surpases body maximum of 35000 character" }
  validates :url, presence: true, if: :url_required?
  before_save :ensure_url_has_protocol, if: :url_required?
  validates :article_type, inclusion: { in: %w(link thread), message: "%{value} is not a valid article type. It must be 'link' or 'thread'" }
  # Method to determine if URL is required based on article type
  def url_required?
    article_type == 'link'
  end
  def ensure_url_has_protocol
    unless url.blank?
      self.url = "http://#{url}" unless url.match?(/\Ahttp(s)?:\/\//)
    end
  end

  def as_custom_json
    as_json(
      include: {
        user: { only: [:id, :username, :email] },
        magazine: { only: [:id, :name] },
        vote_articles: { only: [:id, :value, :user_id] },
        boosts:{ only: [:id, :user_id, :created_at]},
        comments: { only: [:id, :user_id, :parent_id, :body, :created_at]}
      },
      except: [:user_id, :magazine_id]
    )
  end
end