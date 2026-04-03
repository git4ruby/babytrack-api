class AddPhotoToMilestones < ActiveRecord::Migration[8.0]
  def change
    add_column :milestones, :photo_url, :string
  end
end
