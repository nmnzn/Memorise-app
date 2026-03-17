class CreateMemoShares < ActiveRecord::Migration[8.1]
  def change
    create_table :memo_shares do |t|
      t.references :memo, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :memo_shares, [:memo_id, :user_id], unique: true
  end
end
