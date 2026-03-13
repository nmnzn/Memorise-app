class Memo < ApplicationRecord
  belongs_to :user
  has_many :cards, dependent: :destroy
  has_one :chat, dependent: :destroy
  validates :name, presence: true
end
