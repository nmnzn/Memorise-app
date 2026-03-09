class Answer < ApplicationRecord
  belongs_to :card
  belongs_to :user
end
