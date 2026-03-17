class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"
    if @message.save!
      #appeler une méthode qui renvoie une réponse du LLM pour l'afficher dans le chat
      hash_response_from_llm = llm_answering_to_user(@message.content)
      llm_message = hash_response_from_llm["message"]

      unless hash_response_from_llm["complete"]
        message_from_llm = Message.new(content: llm_message, role: "assistant", chat_id: @chat.id)
        if message_from_llm.save!
          redirect_to memo_chat_path(@chat.memo, @chat)
        else
          render "chats/show", status: :unprocessable_entity
        end
      else
        raise
        #appeler le LLM de génération de cards et lui donner l'historique de la conversation
      end
    end
  end







  private

  require 'json'

  def message_params
    params.require(:message).permit(:content)
  end

  def history(messages)
    history = []
    messages.each do |message|
      history.push("Role: #{message.role}, Message: #{message.content}")
    end
    return history.join
  end

  # def build_conversation_history
  #   @chat.messages.each do |message|
  #     @ruby_llm_chat.add_message(message)
  #   end
  # end

  def llm_answering_to_user(message)
    collect_info = <<~PROMPT
      Tu es un assistant pour générer un programme de mémorisation. Ton rôle est de questionner l'utilisateur
      sur son besoin, et reformuler ce que tu as compris en conclusion. Tu dois avoir suffisamment d'information
      sur le sujet à mémoriser et connaître le nombre de cards à générer. Une fois que tu as toutes les informations, reformule
      ce que tu as compris à l'utilisateur pour lui demander son accord.
      Fais des messages courts de quelques mots uniquement, comme des SMS. N'hésite pas à demander du complément d'information si pertinent selon le sujet, 
      mais limite le durée de l'échange au maximum.
      Au final on aura juste besoin de retenir le sujet à mémoriser en quelques lignes, quelques spécificités si pertinentes, et le nombre de questions à mémoriser.

      Voici l'historique des messages échangés (user = l'utilisateur et assistant = tes réponses précédentes) : #{history(@chat.messages)}

      Réponds UNIQUEMENT avec un objet JSON valide, sans markdown, sans balises code, sans texte autour.
      Le format exact est :
      {"complete": false, "message": "ta réponse"}

      La clé "complete" vaut false tant que tu n'as pas toutes les informations, et true quand tu es prêt à générer le programme ET que l'utilisateur 
      a donné son accord après ta reformulation.
      Lorsque complete est true, le message sera "Super, je génère le programme de mémorisation !".
    PROMPT

    output_schema = {
      type: "object",
      properties: {
        complete: { type: "boolean" },
        message:  { type: "string" }
      },
      required: ["complete", "message"],
      additionalProperties: false
    }

    llm_response = RubyLLM.chat.with_schema(output_schema).with_model("gpt-4.1-mini").with_instructions(collect_info).ask(message).content
    #llm_hash = JSON.parse(llm_response)
    return llm_response
  end


end 
