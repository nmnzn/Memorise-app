class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: [:show, :edit, :update, :destroy]
  before_action :set_memo_from_params, only: [:new, :create]
  before_action :authorize_memo_owner!, only: [:new, :create, :edit, :update, :destroy]

  def show
    @memo = @card.memo
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
    @memo = @card.memo
    @card.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("card_#{params[:id]}") }
      format.html { redirect_to memo_path(@memo) }
    end
  end

  def edit
    @memo = @card.memo
  end

  def update
    @memo = @card.memo

    if @card.update(card_params)
      redirect_to memo_path(@memo)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def set_memo_from_params
    @memo = Memo.find(params[:memo_id])
  end

  def authorize_memo_owner!
    memo = @card&.memo || @memo
    return if memo.user == current_user

    redirect_to memos_path, alert: "Seul le propriétaire du mémo peut modifier ses cards."
  end

  def card_params
    params.require(:card).permit(:ask, :answer)
  end
end
