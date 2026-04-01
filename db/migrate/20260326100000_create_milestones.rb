class CreateMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :milestones do |t|
      t.references :baby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :achieved_on, null: false
      t.string :category        # motor, cognitive, social, language, feeding, other
      t.text :notes

      t.timestamps
    end

    add_index :milestones, [ :baby_id, :achieved_on ]
    add_index :milestones, [ :baby_id, :category ]
  end
end
