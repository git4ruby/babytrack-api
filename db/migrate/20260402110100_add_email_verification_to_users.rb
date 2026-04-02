class AddEmailVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_verified, :boolean, default: false, null: false
    add_column :users, :email_verification_token, :string

    # Existing users are already verified
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET email_verified = true"
      end
    end
  end
end
