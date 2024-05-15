class AddNumBoostsToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :num_boosts, :integer, default: 0
  end
end
