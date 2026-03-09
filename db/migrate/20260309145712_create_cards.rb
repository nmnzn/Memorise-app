class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.string :ask
      t.string :question
      t.references :memo, null: false, foreign_key: true

      t.timestamps
    end
  end
end
