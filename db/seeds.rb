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

Faker::Config.locale = 'fr'

puts "Seeding ... "

puts "cleaning models (user already cleaned)..."
Message.destroy_all
Chat.destroy_all
Card.destroy_all
Memo.destroy_all
puts "Models empty except user with test@test.com"

# creation d'un user TEST pour le développement
User.where.not(email: "test@test.com").destroy_all

user = User.find_or_create_by!(email: "test@test.com") do |u|

  u.password   = "password123"
end

puts ">> SEED - USER : test@test.com / password123"





# création de 10 mémos
puts 'SEEDING MEMOS : Creating 10 memos'
10.times do
  memo = Memo.new(
    name:    Faker::Address.city,
    user_id: User.first.id
  )
  memo.save!
end
puts ">>#{Memo.all.count} memos created 💡 for user : #{User.first.email} ☑️"

# création de 50 cards / 10 par mémo
puts 'SEEDING CARDS : Creating 50 cards / 5 per memo'
Memo.all.each do |memo|
  5.times do 
    card = Card.new(
      ask: "Quel est l'adresse de #{Faker::Name.name} ?",
      answer: Faker::Address.full_address,
      memo_id: memo.id
    )
    card.save!
  end 
  puts "5 cards created for memo : #{memo.name}"
end
puts ">>All cards created ! ☑️"

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
end
puts ">>2 answers created for each card ☑️"
puts "_________________________________"

puts "✅ All set ! You have now in your DB : 1 user, 10 memos (topics), 5 cards (question) per memo, 2 answers per card (one true and one false)"


