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

# création de 3 mémos avec cards chacun et enregistrement d'une answer avec des scores au hasard (si score = 1 alors value = true)
puts 'SEEDING  3 MEMOS with CARDS ...'

file_path = File.join(__dir__, "seed.json")
file = File.open(file_path).read
data = JSON.parse file

data.each do |memo_with_cards|
  memo = Memo.new(
    name: memo_with_cards["name"],
    favorite: memo_with_cards["favorite"],
    is_public: memo_with_cards["is_public"],
    user_id: User.first.id
  )
  memo.save!

  card_count = 0
  memo_with_cards["cards"].each do |card|
    kind = card_count.odd? ? :qcm : :flip
    new_card = Card.new(
      ask:         card["ask"],
      answer:      card["answer"],
      memo_id:     memo.id,
      kind:        kind,
      qcm_choices: card["qcm_choices"]
    )
    new_card.save!

    # new_card.answers.first.update(value: card["value"], score: card["score"])
    
    answer = Answer.new(card_id: new_card.id, user_id: memo.user_id, score: card["score"], value: card["value"])
    answer.save!

    card_count += 1
  end
  puts "Memo created (#{memo.name} with #{memo.cards.count} cards) and a record in the table answers. ☑️"
end

puts "✅ All set ! You have now in your DB : 1 user, 3 memos (topics) with cards (question and answer)"
