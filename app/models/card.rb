class Card < ApplicationRecord
  belongs_to :memo
  has_many :answers, dependent: :destroy
  validates :ask, :answer, :memo_id, presence: true
end
