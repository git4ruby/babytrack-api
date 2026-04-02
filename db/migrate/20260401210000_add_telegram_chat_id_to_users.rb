class AddTelegramChatIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :telegram_chat_id, :string
    add_index :users, :telegram_chat_id, unique: true, where: "telegram_chat_id IS NOT NULL"
  end
end
