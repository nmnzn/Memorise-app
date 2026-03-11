class Memo < ApplicationRecord
  belongs_to :user
  has_many :cards, dependent: :destroy

  validates :name, presence: true

  attr_reader :volume, :profondeur

  def self.volume_collection
    return ["Synthétique", "Large"]
  end

  def self.profondeur_collection
    return ["Grandes lignes", "Appronfondie"]
  end
end
