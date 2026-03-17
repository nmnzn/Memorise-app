class MemoShare < ApplicationRecord
  belongs_to :memo
  belongs_to :user

  validates :user_id, uniqueness: { scope: :memo_id }
end
