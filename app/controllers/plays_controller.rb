class PlaysController < ApplicationController
  before_action :set_card, only: [:reveal, :knew, :did_not_know]

  def start

    url = request.referer

    if url.match?(%r{/memos/\d+})
      memo_id = extraire_id(url)
      @memo = nil
      @card = current_user.cards
    elsif params[:memo_id].nil?
      @memo = nil
      @card = current_user.cards
    else
      @memo = Memo.find(params[:memo_id])
      @card = @memo.cards
    end

    session[:play_count] = 0
    if @card.nil?
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    else
      @card = next_unanswered_card
    end
  end

  #def show
    #@cards = current_user.cards.joins(:answers).where(answers:
    # { user: current_user, value: false }).shuffle
    #redirect_to root_path, notice: "vous n'avez pas de card à jouer" if @cards.empty?
    #@card = @cards.first

    #if @card.nil?
      #redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    #end
  #end

  def reveal
    @answer = Answer.find_by(card: @card, user: current_user)
  end

  def knew
    @answer = Answer.find_or_create_by(card: @card, user: current_user)
    new_score = [@answer.score + 0.25, 1.0].min
    @answer.update(score: new_score, value: new_score >= 1.0)

    session[:play_count] += 1
    next_card = next_unanswered_card(exclude: @card.id)

    if next_card
      redirect_to play_path(next_card)
    else
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    end
  end

  def did_not_know
    @answer = Answer.find_or_create_by(card: @card, user: current_user)
    new_score = [@answer.score - 0.25, 0.0].max
    @answer.update(score: new_score, value: false)

    session[:play_count] += 1
    next_card = next_unanswered_card(exclude: @card.id)

    if next_card
      redirect_to play_path(next_card)
    else
      redirect_to play_path(@card)
    end
  end

  private


  def set_card
    @card = current_user.cards.find(params[:id])
  end

  def next_unanswered_card(exclude: nil)
    count = session[:play_count].to_i

    if @memo == nil
      cards = current_user.cards.joins(:answers).where(answers: { user: current_user, value: false })
      cards = cards.where.not(id: exclude) if exclude
    else
      memo_to_play = Memo.find(params[:memo_id])
      cards = memo_to_play.cards.joins(:answers).where(answers: { user: current_user, value: false })
      cards = cards.where.not(id: exclude) if exclude
    end

    if count % 6 == 0 && count > 0
      cards.order("answers.score DESC").first
    elsif count % 3 == 0 && count > 0
      cards.order("answers.score ASC").first
    else
      cards.shuffle.first
    end
  end

  def extraire_id(url)
    #ici je reverse la chaine de caractères pour commencer l'itération sur la fin de l'url comportant l'id, afin d'éviter des nombre dans le reste de l'url
    extract = []
    url.split.reverse.each do |car|
      if car.to_i == 0 || car.to_i == 1 || car.to_i == 2 || car.to_i == 3 || car.to_i == 4 || car.to_i == 5 || car.to_i == 6 || car.to_i == 7 || car.to_i == 8 || car.to_i == 9
        extract.push(car)
      else
        break
      end
    end
    id = extract.reverse.join
    raise
  end
end
