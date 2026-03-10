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
  end

  private

  def memo_params
    params.require(:memo).permit(:content)
  end
end
