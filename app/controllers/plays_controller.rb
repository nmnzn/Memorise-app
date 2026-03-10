class PlaysController < ApplicationController
  def show
    @cards = current_user.cards.shuffle
    @card = @cards.first
  end

  def reveal
    @card = current_user.cards.find(params[:id])
  end
end
