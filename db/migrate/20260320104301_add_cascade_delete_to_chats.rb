class AddCascadeDeleteToChats < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :chats, :memos
    add_foreign_key :chats, :memos, on_delete: :cascade
  end
end
