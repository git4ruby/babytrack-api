class MakeDiaperChangedAtOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :diaper_changes, :changed_at, true
  end
end
