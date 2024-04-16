class CreateArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body
      t.string :article_type
      t.string :url
      t.timestamps
    end
  end
end
