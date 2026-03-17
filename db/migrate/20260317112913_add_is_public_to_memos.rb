class AddIsPublicToMemos < ActiveRecord::Migration[8.1]
  def change
    add_column :memos, :is_public, :boolean
  end
end
