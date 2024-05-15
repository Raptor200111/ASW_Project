class RemoveBoostedAndAuthorFromArticles < ActiveRecord::Migration[7.0]
  def change
    remove_column :articles, :boosted
    remove_column :articles, :author
  end
end
