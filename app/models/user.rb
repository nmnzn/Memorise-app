class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memos, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :cards, through: :memos

  def accessible_memos
    Memo.where(user: self).or(Memo.where(is_public: true)).distinct
  end

  def accessible_cards
    Card.where(memo_id: accessible_memos.select(:id))
  end
end
