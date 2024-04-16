class AddBoostedToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :boosted, :boolean, default: false
  end
end
