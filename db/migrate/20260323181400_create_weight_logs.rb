class CreateWeightLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :weight_logs do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :recorded_at, null: false
      t.integer :weight_grams, null: false
      t.decimal :height_cm, precision: 5, scale: 2
      t.decimal :head_circumference_cm, precision: 5, scale: 2
      t.string :measured_by
      t.text :notes

      t.timestamps
    end

    add_index :weight_logs, [:baby_id, :recorded_at]
  end
end
