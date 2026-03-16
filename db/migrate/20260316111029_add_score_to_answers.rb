class AddScoreToAnswers < ActiveRecord::Migration[8.1]
  def change
    add_column :answers, :score, :float
  end
end
