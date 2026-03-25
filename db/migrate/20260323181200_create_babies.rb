class CreateBabies < ActiveRecord::Migration[8.0]
  def change
    create_table :babies do |t|
      t.string :name, null: false
      t.date :date_of_birth, null: false
      t.string :gender
      t.integer :birth_weight_grams
      t.decimal :birth_length_cm, precision: 5, scale: 2
      t.decimal :head_circumference_cm, precision: 5, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
