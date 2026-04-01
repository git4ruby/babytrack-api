class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :appointment_type, null: false, default: "well_visit"
      t.datetime :scheduled_at, null: false
      t.string :location
      t.string :provider_name
      t.datetime :reminder_at
      t.boolean :reminder_sent, default: false, null: false
      t.string :status, null: false, default: "upcoming"
      t.text :notes

      t.timestamps
    end

    add_index :appointments, [ :baby_id, :scheduled_at ]
    add_index :appointments, :reminder_at
    add_index :appointments, :status
  end
end
