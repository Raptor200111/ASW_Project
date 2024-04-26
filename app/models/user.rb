class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end
  has_many :articles, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :subscriptions
  has_many :subs, through: :subscriptions, source: :magazine
  has_many :boosts
  has_many :boosted_articles, through: :boosts, source: :article
  has_many :vote_articles
  has_many :voted_articles, through: :vote_articles, source: :article
  has_many :comments, dependent: :destroy
  has_many :vote_comments
  has_many :voted_comments, through: :vote_comments, source: :comment
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]


  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.full_name = auth.info.name
      user.avatar_url = auth.info.image
      user.avatar = auth.info.image
    end
  end
end