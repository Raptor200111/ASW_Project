class AddNumCommentsToMagazines < ActiveRecord::Migration[7.0]
  def change
    add_column :magazines, :nComms, :integer, default: 0
  end
end
