class Comment < ApplicationRecord
    belongs_to :article
    belongs_to  :parent, class_name: 'Comment', optional: true
    has_many   :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
    validates :body, presence: true
    belongs_to :user

    has_many :vote_comments
    has_many :voters, through: :vote_comments, source: :user

    def as_json(options = {})
        super(options).merge({ replies: replies.map { |reply| reply.as_json } })
    end

end
