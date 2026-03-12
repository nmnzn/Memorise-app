class Chat < ApplicationRecord
  belongs_to :memo
  has_many :messages
end
