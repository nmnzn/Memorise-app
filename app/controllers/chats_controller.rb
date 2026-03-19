class ChatsController < ApplicationController

  def create
    @memo = Memo.find(params[:memo_id])
    @chat = Chat.new(memo: @memo)
    if @chat.save
      redirect_to memo_chat_path(@memo, @chat)
    else
      redirect_to @memo
    end
  end

  def show
    @memo = Memo.find(params[:memo_id])
    @chat = Chat.find(params[:id])
    @message = Message.new
    # @volume_collection = Message.volume_collection
    # @profondeur_collection = Message.profondeur_collection
  end
end

