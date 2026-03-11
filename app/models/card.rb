class Card < ApplicationRecord
  belongs_to :memo
  has_many :answers, dependent: :destroy
  validates :ask, :answer, :memo_id, presence: true

  after_create :create_default_answers

  private

  def create_default_answers
    Answer.create!(card: self, user: memo.user, value: false)
  end
end

