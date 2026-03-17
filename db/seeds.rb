# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'faker'
require 'json'

Faker::Config.locale = 'fr'

puts "Seeding ... 🌱 "

puts "cleaning models..."
Message.destroy_all
Chat.destroy_all
Card.destroy_all
Memo.destroy_all
Answer.destroy_all


# creation d'un user TEST pour le développement
User.where.not(email: "test@test.com").destroy_all
puts "All models empty"
puts "🗑️ _________ 🗑️"

user = User.find_or_create_by!(email: "test@test.com") do |u|

  u.password   = "password123"
end

puts ">> SEED - USER : test@test.com / password123"

# création de 10 mémos avec 5 cards chacun et mise à jour de la table answers avec des scores au hasard (si score = 1 alors value = true)
puts 'SEEDING  10 MEMOS with 5 CARDS each...'

file_path = File.join(__dir__, "seed.json")
file = File.open(file_path).read
data = JSON.parse file

data.each do |memo_with_cards|
  memo = Memo.new(
    name: memo_with_cards["name"],
    user_id: User.first.id
  )
  memo.save!

    memo_with_cards["cards"].each do |card|
      new_card = Card.new(
        ask: card["ask"],
        answer: card["answer"],
        memo_id: memo.id
      )
      new_card.save!
      new_card.answers.first.update(value: card["value"])
      new_card.answers.first.update(score: card["score"])
    end
  puts "Memo created (#{memo.name} with #{memo.cards.count} cards) and different answers scores (one answer record per card-user) ☑️"
end

puts "✅ All set ! You have now in your DB : 1 user, 10 memos (topics), 5 cards (question and answer) per memo, 2 answers (recorded) per card (one true and one false)"


