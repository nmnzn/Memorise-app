class CardsController < ApplicationController
  def show
    @card = Card.find(params[:id])
  end

  def new
    @card = Card.new
  end

  def create
    @card = Card.new(card_params)
    @card.memo = Memo.find(params[:memo_id])
    @card.save
    redirect_to memo_path(@card.memo)
  end

  def destroy
    @card = Card.find(params[:id])
    @card.destroy
    redirect_to memo_path(@card.memo)
  end

  private

  def card_params
    params.require(:card).permit(:ask, :question)
  end
end
