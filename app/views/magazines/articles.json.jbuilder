json.partial! "magazines/magazine", magazine: @magazine

json.articles @magazine.articles do |article|
  json.id article.id
  json.title article.title
  json.body article.body
end
