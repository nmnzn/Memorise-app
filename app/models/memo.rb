class Memo < ApplicationRecord
  belongs_to :user
  has_many :cards, dependent: :destroy

  validates :name, presence: true
  validates :prompt, presence: true
end
