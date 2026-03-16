class PlaysController < ApplicationController
  before_action :set_card, only: [:reveal, :knew, :did_not_know]

  def start
    raise
    if params[:memo_id].nil?
      @memo = nil
    else
      @memo = Memo.find(params[:memo_id])
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
end
