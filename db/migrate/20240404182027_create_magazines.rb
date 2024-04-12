class CreateMagazines < ActiveRecord::Migration[7.0]
  def change
    create_table :magazines do |t|
      t.string :name
      t.string :title
      t.string :url

      t.timestamps
    end
  end
end
