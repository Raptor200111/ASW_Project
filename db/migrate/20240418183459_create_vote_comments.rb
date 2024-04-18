class CreateVoteComments < ActiveRecord::Migration[7.0]
  def change
    create_table :vote_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
