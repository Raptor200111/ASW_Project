class AddApiKeyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :api_key, :string, unique: true
    User.find_each do |u|
      u.update_columns(api_key: SecureRandom.base58(24))
    end
  end
end
