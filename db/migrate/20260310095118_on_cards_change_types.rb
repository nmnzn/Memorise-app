class OnCardsChangeTypes < ActiveRecord::Migration[8.1]
  def change
    change_column :cards, :ask, :text
    change_column :cards, :answer, :text
  end
end
