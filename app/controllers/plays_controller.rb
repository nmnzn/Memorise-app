class PlaysController < ApplicationController
  def show
    @cards = current_user.cards.joins(:answers).where(answers:
     { user: current_user, value: false }).shuffle
    redirect_to root_path, notice: "vous n'avez pas de card à jouer" if @cards.empty?
    @card = @cards.first
  end

  def reveal
    @card = current_user.cards.find(params[:id])
    @answer = Answer.find_by(card: @card, user: current_user)
  end
end
