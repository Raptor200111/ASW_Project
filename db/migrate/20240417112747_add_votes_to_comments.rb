class AddVotesToComments < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :votes_up, :integer
    add_column :comments, :votes_down, :integer
  end
end
