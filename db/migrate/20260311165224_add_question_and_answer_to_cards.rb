class AddQuestionAndAnswerToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :question, :string
    add_column :cards, :answer, :text
  end
end
