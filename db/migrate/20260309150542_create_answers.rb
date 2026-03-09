class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :card, null: false, foreign_key: true
      t.boolean :value
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
