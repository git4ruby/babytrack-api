class AddTermsAcceptedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :terms_accepted_at, :datetime, null: true
  end
end
