class AddUserIdToBabies < ActiveRecord::Migration[8.0]
  def change
    add_reference :babies, :user, null: true, foreign_key: true

    # Assign existing babies to first user
    reversible do |dir|
      dir.up do
        execute "UPDATE babies SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1) WHERE user_id IS NULL"
      end
    end
  end
end
