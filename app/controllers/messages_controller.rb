class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"
    if @message.save!
      #appeler une méthode qui renvoie une réponse du LLM pour l'afficher dans le chat
      answer = llm_answering_to_user(@message.content)
      message_from_llm = Message.new(content: answer, role: "assistant", chat_id: @chat.id)
      if message_from_llm.save!
        redirect_to memo_chat_path(@chat.memo, @chat)
      else
        render "chats/show", status: :unprocessable_entity
      end
    end
  end







  private

  def message_params
    params.require(:message).permit(:content)
  end

  def llm_answering_to_user(message)
    collect_info = "Tu es un assistant afin de générer un programme de mémorisation, ton rôle est de question l'utilisateur
    sur son besoin, et reformuler ce que tu as compris en conclusion. Tu dois avoir suffisement d'information sur le sujet à 
    mémoriser et connaitre le nombre de cards à générer."
    RubyLLM.chat.with_instructions(collect_info).ask(message).content
  end

end
