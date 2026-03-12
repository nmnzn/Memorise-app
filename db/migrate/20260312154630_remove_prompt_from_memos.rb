class RemovePromptFromMemos < ActiveRecord::Migration[8.1]
  def change
    remove_column :memos, :prompt, :text
  end
end
