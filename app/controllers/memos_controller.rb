class MemosController < ApplicationController
  def index
    @memos = current_user.memos
  end

  def new
    @memo = Memo.new
  end
end
