class AddMagazineRefToArticles < ActiveRecord::Migration[7.0]
  def change
    add_reference :articles, :magazine, null: false, foreign_key: true
  end
end
