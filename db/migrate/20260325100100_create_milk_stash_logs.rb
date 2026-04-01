class CreateMilkStashLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :milk_stash_logs do |t|
      t.references :milk_stash, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false                 # consumed, discarded, transferred
      t.integer :volume_ml, null: false             # how much was taken/discarded/transferred
      t.string :destination_storage_type            # for transfers: fridge or freezer
      t.references :feeding, null: true, foreign_key: true # optional: link to feeding record
      t.string :reason                              # for discards: expired, spilled, contaminated, other
      t.text :notes

      t.timestamps
    end

    add_index :milk_stash_logs, [ :milk_stash_id, :action ]
  end
end
