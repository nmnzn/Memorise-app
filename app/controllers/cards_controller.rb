class CardsController < ApplicationController
  def show
    @card = Card.find(params[:id])
    @memo = @card.memo
  end

  def new
    @card = Card.new
    @memo = Memo.find(params[:memo_id])
  end

  def create
    @card = Card.new(card_params)
    @memo = Memo.find(params[:memo_id])
    @card.memo = @memo
    if @card.save
      redirect_to new_memo_card_path(@memo)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @card = Card.find(params[:id])
    @card.destroy
    redirect_to memo_path(@card.memo)
  end

  private

  def card_params
    params.require(:card).permit(:ask, :answer)
  end
end
