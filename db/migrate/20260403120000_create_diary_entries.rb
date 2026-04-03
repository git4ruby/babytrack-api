class CreateDiaryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :diary_entries do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :entry_date, null: false
      t.text :content, null: false
      t.string :mood, null: false, default: "neutral"
      t.string :photo_url

      t.timestamps
    end

    add_index :diary_entries, [ :baby_id, :entry_date ]
  end
end
