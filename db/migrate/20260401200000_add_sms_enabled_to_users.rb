class AddSmsEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sms_enabled, :boolean, default: false, null: false

    # Enable SMS for existing users (you)
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET sms_enabled = true WHERE id = 1"
      end
    end
  end
end
