class Chat < ApplicationRecord
  belongs_to :memo
  has_many :messages

  attr_reader :volume, :profondeur, :prompt

  def self.volume_collection
    ["Synthétique", "Large"]
  end

  def self.profondeur_collection
    ["Grandes lignes", "Appronfondie"]
  end
end
