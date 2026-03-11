class AddPromptToMemos < ActiveRecord::Migration[8.1]
  def change
    add_column :memos, :prompt, :text
  end
end
