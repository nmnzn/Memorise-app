class PlaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: %i[knew did_not_know]
  before_action :set_card, only: %i[show reveal knew did_not_know]

  def start
    if params[:memo_id]
      @memo = Memo.find(params[:memo_id])
      session[:memo_id] = @memo.id
    else
      @memo = nil
      session.delete(:memo_id)
    end

    # Determine which cards to play: memo cards or all user cards
    @cards = @memo ? @memo.cards : current_user.cards

    # Initialize play session counter
    session[:play_count] = 0
    if @cards.empty?
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    else
      @card = next_unanswered_card
      if @card
        @mode = @card.qcm? && @card.qcm_choices.present? ? :qcm : :flip
      else
        redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
      end
    end
  end

  def show
    @mode = @card.qcm? && @card.qcm_choices.present? ? :qcm : :flip
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
    # Get the current play count to determine card selection strategy.
    count = session[:play_count].to_i

    # Determine which cards to study from (memo or all user cards).
    base_cards = @memo ? @memo.cards : current_user.cards

    # Exclude current card if specified.
    base_cards = base_cards.where.not(id: exclude) if exclude

    # Keep cards that are not yet mastered by the current user.
    mastered_card_ids = current_user.answers
                                    .where(card_id: base_cards.select(:id), value: true)
                                    .select(:card_id)

    study_cards = base_cards.where.not(id: mastered_card_ids).to_a
    return nil if study_cards.empty?

    # Build a per-user score map once to avoid SQL joins on other users' answers.
    answers_by_card_id = current_user.answers
                                     .where(card_id: study_cards.map(&:id))
                                     .index_by(&:card_id)

    # Select next card based on spaced repetition strategy.
    sorted_by_score = study_cards.sort_by { |card| answers_by_card_id[card.id]&.score || 0.5 }

    if count % 6 == 0 && count > 0
      # Every 6 cards: review hardest cards (lowest score first).
      sorted_by_score.first
    elsif count % 3 == 0 && count > 0
      # Every 3 cards: review easiest cards (highest score first).
      sorted_by_score.last
    else
      # Otherwise: random selection for variety.
      study_cards.sample
    end
  end
end
