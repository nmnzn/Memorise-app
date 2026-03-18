class PlaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: [:knew, :did_not_know]
  before_action :set_card, only: [:show, :reveal, :knew, :did_not_know]

  def start

  if params[:memo_id].present?
    @memo = Memo.find(params[:memo_id])
    session[:memo_id] = @memo.id
  else
    @memo = nil
    session.delete(:memo_id)
  end

  @cards = @memo ? @memo.cards : current_user.cards

    session[:play_count] = 0
    if @cards.nil?
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    else
      @card = next_unanswered_card
      @mode = (@card.qcm? && @card.qcm_choices.present?) ? :qcm : :flip
    end
  end

  def show
    @mode = (@card.qcm? && @card.qcm_choices.present?) ? :qcm : :flip
  end

  def knew
    @answer = Answer.find_or_create_by(card: @card, user: current_user)
    new_score = [@answer.score.to_f + 0.25, 1.0].min
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
    new_score = [@answer.score.to_f - 0.25, 0.0].max
    @answer.update(score: new_score, value: false)

    session[:play_count] += 1
    next_card = next_unanswered_card(exclude: @card.id)

    if @card.qcm?
      session[:next_card_id] = next_card&.id
      redirect_to reveal_play_path(@card)
    elsif next_card
      redirect_to play_path(next_card)
    else
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    end
  end

  def reveal
    @next_card_id = session.delete(:next_card_id)
  end

  private

  def set_card
    @card = current_user.accessible_cards.find(params[:id])
  end

  def set_memo
    @memo = session[:memo_id] ? Memo.find_by(id: session[:memo_id]) : nil
  end

  def next_unanswered_card(exclude: nil)
    count = session[:play_count].to_i

    if @memo == nil
      cards = current_user.cards.joins(:answers).where(answers: { user: current_user, value: false })
      cards = cards.where.not(id: exclude) if exclude
    else
      memo_to_play = @memo
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
