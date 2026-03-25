class CreateDiaperChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :diaper_changes do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :changed_at, null: false
      t.string :diaper_type, null: false           # wet, soiled, both, dry
      t.string :stool_color                         # yellow, green, brown, black, orange, red
      t.string :consistency                         # normal, loose, watery, hard, seedy, mucousy
      t.boolean :has_rash, default: false, null: false
      t.text :notes

      t.timestamps
    end

    add_index :diaper_changes, [:baby_id, :changed_at]
    add_index :diaper_changes, [:baby_id, :diaper_type]
  end
end
