class CreateBabyShares < ActiveRecord::Migration[8.0]
  def change
    create_table :baby_shares do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "caregiver"  # caregiver, viewer
      t.string :invite_token
      t.string :invite_email
      t.string :status, null: false, default: "pending"   # pending, accepted
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :baby_shares, [ :baby_id, :user_id ], unique: true
    add_index :baby_shares, :invite_token, unique: true
  end
end
