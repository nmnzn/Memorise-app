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

puts "Seeding ... "

puts "cleaning models (user already cleaned)..."
Message.destroy_all
Chat.destroy_all
Card.destroy_all
Memo.destroy_all
puts "Models empty except user with test@test.com"
puts "🗑️ _________ 🗑️"

# creation d'un user TEST pour le développement
User.where.not(email: "test@test.com").destroy_all

user = User.find_or_create_by!(email: "test@test.com") do |u|

  u.password   = "password123"
end

puts ">> SEED - USER : test@test.com / password123"





# création de 10 mémos avec 5 cards chacun
puts 'SEEDING  10 MEMOS with 5 CARDS each...'

file_path = File.join(__dir__, "..", "seed.json")
p file_path
file = File.read(file_path)
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
    end
  puts "Memo created (#{memo.name} with #{memo.cards.count} cards) ☑️"
end

# création de 2 answers per memo (une réponse vraie et une fausse) (jointure avec user id, card id, value (true/false))
puts "SEEDING ANSWER : creating one true answer and one false answer (join table) for each card (100 records) / we have only one user here"
Card.all.each do |card|

  answer_true = Answer.new(
    user_id: User.first.id,
    card_id: card.id,
    value: true
  )
  answer_true.save!

  answer_false = Answer.new(
    user_id: User.first.id,
    card_id: card.id,
    value: false
  )
  answer_false.save!
  # puts "2 answers recorded for this question (#{card.ask}) - #{answer_true.value} and #{answer_false.value}"
end
puts ">>2 answers created for each card (true and false) ☑️"
puts "_________________________________"

puts "✅ All set ! You have now in your DB : 1 user, 10 memos (topics), 5 cards (question and answer) per memo, 2 answers (recorded) per card (one true and one false)"


