class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.content.blank?
      @message.errors.add(:content, "Le sujet ne peut pas être vide.")
      render "chats/show", status: :unprocessable_entity
    elsif @message.save
      LlmChatJob.perform_later(@chat.id, @message.id)
      @messages = @chat.messages.reload
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to memo_chat_path(@chat.memo, @chat) }
      end
    else
      render "chats/show", status: :unprocessable_entity
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
      history.push("Role: #{message.role}, Message: #{message.content} -")
    end
    return history.join
  end

  # def build_conversation_history
  #   @chat.messages.each do |message|
  #     @ruby_llm_chat.add_message(message)
  #   end
  # end

  def llm_answering_to_user(message, history)
    collect_info = <<~PROMPT
    Tu es un assistant sympa qui aide à créer un programme de mémorisation.

    Si le sujet n'est pas encore donné → demande-le avec curiosité.
    Si le nombre de cartes n'est pas donné → demande-le naturellement (max 50, précise le à l'utilisateur s'il en demande plus que 50, sinon ne parle pas de cette limite)
    Si le sujet est large ou vague → pose une petite question de précision
    Important : Une fois tout clair et que tu es pense avoir suffisemment d'information pour générer un programme de mémorisation (question/réponses) → fais un court récap avant de lancer la génération ET demande l'accord à l'utlisateur pour générer le programme.

    Quelques règles :
    Messages courts et chaleureux, pas de blabla, style SMS
    Evite trop de redondance dans tes messages sauf lorsque tu récapitules en fin de conversation avant de générer le programme. 
    Idéalement, il y a 3-4 échanges, si besoin tu peux étendre légèrement la conversation. L'important est de comprendre le besoin utilisateur et attendre son accord (important) pour lancer la génération de cartes.
    Si l'utilisateur demande plus de 50 cartes → explique gentiment la limite et demande combien il veut finalement
    Si le sujet est trop récent ou inconnu → sois honnête, explique que tu n'as pas d'infos fiables et propose de reformuler
    Format JSON uniquement (aucun texte autour) : {"complete": false, "message": "..."}

    complete: false → tant que tu n'as pas tout ce qu'il faut ET que tu n'as pas obtenu l'accord de l'utilisateur pour générer le prorgamme de mémorisation. ALORS la clé "resume" a une string vide comme valeur, et la clé "number" a une valeur 0 (jamais "nil").
    complete: true → une fois le récap validé par l'utilisateur ET que tu as son accord pour générer le programme (en réponse de ton récapitulatif). Message : "Super, je génère le programme !"
    Quand complete: true → tu dois obligatoirement générer un "resume" (résumé du besoin) et "number" (nombre de cartes demandé)
    Historique de la conversation : #{history}

    PROMPT

    output_schema = {
      type: "object",
      properties: {
        complete: { type: "boolean" },
        message: { type: "string" },
        resume: { type: "string" },
        number: { type: "integer" }
      },
      required: ["complete", "message", "resume", "number"],
      additionalProperties: false
    }

    Rails.logger.info "\n=== LLM HISTORY ===\n#{history}\n==================\n"
    llm_response = RubyLLM.chat.with_schema(output_schema).with_instructions(collect_info).ask(message).content
    # llm_hash = JSON.parse(llm_response)
    return llm_response
  end





  def generate_cards_with_llm(user_prompt, nb_cards, history)
    instructions = <<~PROMPT
      Tu es Memorise, une application faite pour aider l'utilisateur à se souvenir des choses, simplement et naturellement. Ton ton : clair, concis, utile. Pas de blabla. Pas de texte inutile.

      Ton objectif : proposer des cards (question et réponse associée) pertinentes pour l'utilisateur, en te basant uniquement sur ce qui est explicitement présent dans la conversation et dans le prompt utilisateur : le sujet demandé et quelques précisions au besoin.
      Avec le sujet donné, génère des paires question - réponse pertinentes, concises, et intéressantes.

      Méthode :
      1) Comprends l'intention : déduis les éléments les plus utiles à mémoriser à partir du sujet demandé.
      2) Génère #{nb_cards} cards (question/réponse).
      3) Pour rappel, tu génères 50 cards au maximum.
      4) Tu peux mettre quelques emojis pertinents. Ne crée pas de code ou autre élément, propose juste les questions/réponses. Garde un langage agréable et du quotidien, sans être trop familier.
      5) Ne donne aucune explication, aucun commentaire, aucune introduction. Uniquement les cards (question/réponse).
      
      Historique de la conversation pour alimenter tes questions/réponses en plus du prompt utilisateur : #{history}
    PROMPT

    output_schema = {
      type: "object",
      properties: {
        cards: {
          type: "array",
          items: {
            type: "object",
            properties: {
              question: { type: "string" },
              answer: { type: "string" }
            },
            required: ["question", "answer"],
            additionalProperties: false
          }
        }
      },
      required: ["cards"],
      additionalProperties: false
    }
    RubyLLM.chat.with_schema(output_schema).with_instructions(instructions).ask(user_prompt).content
  end
end
