class Message < ApplicationRecord
  belongs_to :chat

  # acts_as_message

  # attr_reader :volume, :profondeur

  # def self.volume_collection
  #   ["Synthétique", "Large"]
  # end

  # def self.profondeur_collection
  #   ["Grandes lignes", "Appronfondie"]
  # end
end
