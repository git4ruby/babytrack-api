class CreateSleepLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sleep_logs do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration_minutes
      t.string :sleep_type, null: false, default: "nap"  # nap, night
      t.string :location                                   # crib, bassinet, stroller, car, arms
      t.text :notes

      t.timestamps
    end

    add_index :sleep_logs, [ :baby_id, :started_at ]
  end
end
