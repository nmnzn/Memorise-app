class Card < ApplicationRecord
  belongs_to :memo, inverse_of: :cards
  has_many :answers, dependent: :destroy

  enum :kind, { flip: 1, qcm: 2 }, default: :flip

  validates :ask,    presence: true
  validates :answer, presence: true

  after_create_commit :create_default_answers
  after_create_commit :schedule_qcm_generation, if: :qcm?
  after_update_commit :invalidate_qcm,          if: -> { qcm? && saved_change_to_answer? }

  private

  def create_default_answers
    Answer.create!(card: self, user: memo.user, value: false)
  end

  def schedule_qcm_generation
    QcmGeneratorJob.perform_later(id)
  end

  def invalidate_qcm
    update_columns(qcm_choices: nil)
    QcmGeneratorJob.perform_later(id)
  end
end

