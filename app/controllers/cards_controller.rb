class CardsController < ApplicationController
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
    @memo = @card.memo
    @card.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("card_#{params[:id]}") }
      format.html { redirect_to memo_path(@memo) }
    end
  end

  def edit
    @card = Card.find(params[:id])
    @memo = Memo.find(@card.memo_id)
  end

  def update
    @card = Card.find(params[:id])
    @memo = Memo.find(params[:memo_id])
    if @card.update(card_params)
      redirect_to memo_path(@memo)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def card_params
    params.require(:card).permit(:ask, :answer)
  end
end
