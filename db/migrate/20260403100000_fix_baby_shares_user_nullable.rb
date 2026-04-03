class FixBabySharesUserNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :baby_shares, :user_id, true
  end
end
