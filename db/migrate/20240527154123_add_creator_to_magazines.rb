class AddCreatorToMagazines < ActiveRecord::Migration[7.0]
  def change
    add_column :magazines, :creator_id, :integer
  end
end
