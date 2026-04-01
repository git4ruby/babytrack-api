class CreateFeedings < ActiveRecord::Migration[8.0]
  def change
    create_table :feedings do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :feed_type, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :duration_minutes
      t.integer :volume_ml
      t.string :breast_side
      t.string :milk_type
      t.string :formula_brand
      t.text :notes
      t.uuid :session_group
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :feedings, [ :baby_id, :started_at ]
    add_index :feedings, :session_group
    add_index :feedings, :discarded_at
    add_index :feedings, :feed_type
  end
end
