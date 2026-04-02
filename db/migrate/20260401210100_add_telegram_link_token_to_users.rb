class AddTelegramLinkTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :telegram_link_token, :string
  end
end
