json.extract! magazine, :id, :name, :title, :description, :rules, :created_at, :updated_at
json.nThreads magazine.articles.size
json.nComms magazine.nComms
json.nSubs magazine.subscribers.size
json.url magazine_url(magazine, format: :json)