class Answer < ApplicationRecord
  belongs_to :card
  belongs_to :user
  after_initialize :set_default_score, if: :new_record?

  private

  def set_default_score
    self.score ||= 0.5
  end
end
