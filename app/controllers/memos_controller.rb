class MemosController < ApplicationController
  def index
    @memos = current_user.memos
  end

  def show
    @memo = Memo.find(params[:id])
  end

  def new
    @memo = Memo.new
  end

  def create
    @memo = Memo.new(memo_params)
    @memo.user = current_user

    if @memo.save
      redirect_to memos_path, notice: "Le mémo a bien été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def memo_params
    params.require(:memo).permit(:name)
  end
end
