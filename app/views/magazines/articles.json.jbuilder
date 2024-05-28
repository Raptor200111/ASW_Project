json.extract! @magazine, :id, :name

json.articles @magazine.articles do |article|
  json.extract! article, :id, :body, :article_type, :url, :votes_up, :votes_down, :user_id, :num_boosts
end