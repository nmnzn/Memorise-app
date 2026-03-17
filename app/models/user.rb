class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memos, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :cards, through: :memos

  has_many :memo_shares, dependent: :destroy
  has_many :shared_memos, through: :memo_shares, source: :memo

  def accessible_memos
    Memo
      .left_joins(:memo_shares)
      .where("memos.user_id = :user_id OR memo_shares.user_id = :user_id", user_id: id)
      .distinct
  end

  def accessible_cards
    Card.where(memo_id: accessible_memos.select(:id))
  end
end
