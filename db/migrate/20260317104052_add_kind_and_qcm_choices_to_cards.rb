class AddKindAndQcmChoicesToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :kind, :integer, default: 1, null: false
    add_column :cards, :qcm_choices, :jsonb
  end
end
