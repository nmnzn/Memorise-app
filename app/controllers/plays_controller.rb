class PlaysController < ApplicationController
  before_action :set_card, only: [:reveal, :knew, :did_not_know]

  def start
    first_card = current_user.cards
                             .joins(:answers)
                             .where(answers: { user: current_user, value: false })
                             .shuffle
                             .first

    if first_card
      redirect_to play_path(first_card)
    else
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    end
  end

  def show
    @cards = current_user.cards
                         .joins(:answers)
                         .where(answers: { user: current_user, value: false })
                         .shuffle

    @card = @cards.first

    if @card.nil?
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    end
  end

  def reveal
    @answer = Answer.find_by(card: @card, user: current_user)
  end

  def knew
    @answer = Answer.find_or_create_by(card: @card, user: current_user)
    @answer.update(value: true)

    next_card = current_user.cards
                            .joins(:answers)
                            .where(answers: { user: current_user, value: false })
                            .where.not(id: @card.id)
                            .shuffle
                            .first

    if next_card
      redirect_to play_path(next_card)
    else
      redirect_to memos_path, notice: "Bravo, tu as terminé toutes les cards."
    end
  end

  def did_not_know
    @answer = Answer.find_or_create_by(card: @card, user: current_user)
    @answer.update(value: false)

    next_card = current_user.cards
                            .joins(:answers)
                            .where(answers: { user: current_user, value: false })
                            .where.not(id: @card.id)
                            .shuffle
                            .first

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
end
