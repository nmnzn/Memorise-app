class MemosController < ApplicationController
  def index
    @memos = current_user.memos
  end

  
end
