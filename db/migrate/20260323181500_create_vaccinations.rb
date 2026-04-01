class CreateVaccinations < ActiveRecord::Migration[8.0]
  def change
    create_table :vaccinations do |t|
      t.references :baby, null: false, foreign_key: true
      t.string :vaccine_name, null: false
      t.text :description
      t.integer :recommended_age_days
      t.date :administered_at
      t.string :administered_by
      t.string :lot_number
      t.string :site
      t.text :reactions
      t.boolean :reminder_sent, default: false, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :vaccinations, [ :baby_id, :status ]
  end
end
