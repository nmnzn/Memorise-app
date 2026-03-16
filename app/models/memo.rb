class Memo < ApplicationRecord
  belongs_to :user
  has_many :cards, dependent: :destroy, inverse_of: :memo
  has_one :chat, dependent: :destroy

  accepts_nested_attributes_for :cards, reject_if: :all_blank

  validates :name, presence: true
end
