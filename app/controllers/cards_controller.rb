class CardsController < ApplicationController
  before_action :set_memo, only: %i[new create show destroy]

  def show
    @card = @memo.cards.find(params[:id])
  end

  def new
    @card = Card.new
  end

  def create
    @card = Card.new(card_params)
    @card.memo = @memo

    if @card.save
      redirect_to new_memo_card_path(@memo)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @card = @memo.cards.find(params[:id])
    @card.destroy
    redirect_to memo_path(@memo)
  end

  private

  def set_memo
    @memo = Memo.find(params[:memo_id])
  end

  def card_params
    params.require(:card).permit(:ask, :answer)
  end
end
