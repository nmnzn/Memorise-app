class OnCardsChangeColumnQuestionByAnswer < ActiveRecord::Migration[8.1]
  def change
    rename_column :cards, :question, :answer
  end
end
