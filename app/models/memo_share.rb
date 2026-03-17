class MemoShare < ApplicationRecord
  belongs_to :memo
  belongs_to :user

  validates :user_id, uniqueness: { scope: :memo_id }
end










mémo show boyton is_public




champ sur les cards
