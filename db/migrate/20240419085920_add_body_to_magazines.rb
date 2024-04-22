class AddBodyToMagazines < ActiveRecord::Migration[7.0]
  def change
    add_column :magazines, :description, :string
    add_column :magazines, :rules, :string

  end
end
