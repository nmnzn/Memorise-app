class Card < ApplicationRecord
  belongs_to :memo
  has_many :answers, dependent: :destroy
end
