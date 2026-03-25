class CreateMilkStashes < ActiveRecord::Migration[8.0]
  def change
    create_table :milk_stashes do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :volume_ml, null: false
      t.integer :remaining_ml, null: false
      t.string :storage_type, null: false          # fridge, freezer
      t.string :status, null: false, default: "available" # available, consumed, discarded, expired
      t.string :source_type, null: false, default: "pumped" # pumped, donated
      t.string :label                               # e.g. "Bag #3", "Morning pump"
      t.datetime :stored_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :thawed_at                         # when moved from freezer to fridge
      t.text :notes

      t.timestamps
    end

    add_index :milk_stashes, [:baby_id, :status]
    add_index :milk_stashes, [:baby_id, :storage_type]
    add_index :milk_stashes, :expires_at
  end
end
