class AddVotesToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :votes_up, :integer, default:0
    add_column :articles, :votes_down, :integer, default:0
  end
end
