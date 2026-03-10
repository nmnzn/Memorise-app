# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "faker"

# creation d'un user TEST pour le développement
User.where.not(email: "test@test.com").destroy_all

user = User.find_or_create_by!(email: "test@test.com") do |u|

  u.password   = "password123"
end

puts "Seed OK - user: test@test.com / password123"

# création de 10 mémos
puts 'Creating 10 memos'
10.times do
  memo = Memo.new(
    name:    Faker::Educator.subject,
    user_id: User.first.id
  )
  memo.save!
end
puts "10 memos created 💡 for user : #{User.first.email}"

# création de 50 cards / 10 par mémo
puts 'Creating 50 cards / 5 per memo'
50.times do
  card = Card.new(
    ask:    Faker::Educator.subject,
    question
    user_id: User.first.id
  )
  card.save!
end
puts "10 memos created 💡 for user : #{User.first.email}"
