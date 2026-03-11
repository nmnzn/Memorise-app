class Memo < ApplicationRecord
  belongs_to :user
  has_many :cards, dependent: :destroy
  validates :name, presence: true
  validates :prompt, presence: true

  attr_reader :volume, :profondeur

  def self.volume_collection
    ["Synthétique", "Large"]
  end

  def self.profondeur_collection
    ["Grandes lignes", "Appronfondie"]
  end
end
