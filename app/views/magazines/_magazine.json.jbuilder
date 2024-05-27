json.extract! magazine, :id, :name, :title, :description, :rules, :created_at, :updated_at, :creator_id, :url
json.nThreads magazine.articles.size
json.nComms magazine.nComms
json.nSubs magazine.subscribers.size
