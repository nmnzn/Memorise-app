class Chat < ApplicationRecord
  belongs_to :memo
  has_many :messages, dependent: :destroy
  acts_as_chat
end
