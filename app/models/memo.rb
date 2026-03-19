class Memo < ApplicationRecord
  belongs_to :user

  has_many :cards, dependent: :destroy, inverse_of: :memo
  has_one :chat, dependent: :destroy
  has_many :memo_shares, dependent: :destroy
  has_many :shared_users, through: :memo_shares, source: :user

  has_many :memo_shares, dependent: :destroy
  has_many :shared_users, through: :memo_shares, source: :user

  accepts_nested_attributes_for :cards, reject_if: :all_blank

  validates :name, presence: true

  def accessible_by?(user)
    self.user == user || shared_users.exists?(id: user.id) || is_public?
  end

  def owned_by?(user)
    self.user == user
  end

  def visibility_label
    is_public? ? "Public" : "Privé"
  end

  def favorite_label
    favorite? ? "Retirer des favoris" : "Ajouter aux favoris"
  end
end
