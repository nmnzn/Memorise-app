require 'json'

# création de 10 mémos avec 5 cards chacun
file = File.open("../seed.json").read
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
  puts "Memo created (#{memo.name} with #{memo.cards.count} cards)"
end