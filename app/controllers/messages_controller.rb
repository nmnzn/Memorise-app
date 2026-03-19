class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.content.blank?
      @message.errors.add(:content, "Le sujet ne peut pas être vide.")
      render "chats/show", status: :unprocessable_entity
    else
      if @message.save
        #appeler une méthode qui renvoie une réponse du LLM pour l'afficher dans le chat
        chat_history = history(@chat.messages)

        hash_response_from_llm = llm_answering_to_user(@message.content, chat_history)

        assistant_message = hash_response_from_llm["message"]
        assistant_resume = hash_response_from_llm["resume"]
        assistant_nb_cards = hash_response_from_llm["number"]

        unless hash_response_from_llm["complete"]
          message_from_llm = Message.new(content: assistant_message, role: "assistant", chat_id: @chat.id)
          if message_from_llm.save!
            @messages = @chat.messages.reload
            respond_to do |format|
              format.turbo_stream
              format.html { redirect_to memo_chat_path(@chat.memo, @chat) }
            end

          else
            render "chats/show", status: :unprocessable_entity
          end
        else
          #appeler le LLM de génération de cards et lui donner l'historique de la conversation
          object_with_array_of_hash_cards_from_llm = generate_cards_with_llm(assistant_resume, assistant_nb_cards)
          llm_cards = object_with_array_of_hash_cards_from_llm["cards"]
          unless llm_cards.is_a?(Array)
            @message.errors.add(:base, "La génération des cards a échoué.")
            render "chats/show", status: :unprocessable_entity
            return
          end

          card_count = 0
          llm_cards.each do |card_data|
            next unless card_data.is_a?(Hash)

            question = card_data["question"] || card_data[:question]
            answer   = card_data["answer"]   || card_data[:answer]

            next if question.blank? || answer.blank?

            kind = card_count.odd? ? :qcm : :flip
            @chat.memo.cards.create!(ask: question, answer: answer, kind: kind)
            card_count += 1
          end
          redirect_to memo_path(@chat.memo), notice: "Les cards ont bien été créées."
        end
      else
        render "chats/show", status: :unprocessable_entity
      end
    end
  rescue JSON::ParserError
    @message.errors.add(:base, "La réponse de l'IA est invalide.")
    render "chats/show", status: :unprocessable_entity
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

    Tu es un assistant sympa qui aide à créer un programme de mémorisation. Ton rôle est de comprendre le besoin de l'utilisateur, à son rythme, pour générer des cartes de mémorisation.
    Déroule la conversation dans cet ordre :

    Si le sujet n'est pas encore donné → demande-le avec curiosité
    Si le nombre de cartes n'est pas donné → demande-le naturellement (max 100)
    Si le sujet est large ou vague → pose une petite question de précision
    Une fois tout clair → fais un court récap avant de lancer la génération

    Quelques règles :
    Messages courts et chaleureux, pas de blabla, style SMS
    Max 4 échanges, pas plus, pour éviter de perdre l'utilisateur
    Si l'utilisateur demande plus de 100 cartes → explique gentiment la limite et demande combien il veut finalement
    Si le sujet est trop récent ou inconnu → sois honnête, explique que tu n'as pas d'infos fiables et propose de reformuler
    Format JSON uniquement (aucun texte autour) : {"complete": false, "message": "..."}

    complete: false → tant que tu n'as pas tout ce qu'il faut
    complete: true → une fois le récap validé. Message : "Super, je génère le programme !"
    Quand complete: true → ajoute "resume" (résumé du besoin) et "number" (nombre de cartes)
    Historique : #{history}

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

    llm_response = RubyLLM.chat.with_schema(output_schema).with_instructions(collect_info).ask(message).content
    # llm_hash = JSON.parse(llm_response)
    return llm_response
  end





  def generate_cards_with_llm(user_prompt, nb_cards)
    instructions = <<~PROMPT
      Tu es Memorise, une application faite pour aider l'utilisateur à se souvenir des choses, simplement et naturellement. Ton ton : clair, concis, utile. Pas de blabla. Pas de texte inutile.

      Ton objectif : proposer des cards (question et réponse associée) pertinentes pour l'utilisateur, en te basant uniquement sur ce qui est explicitement présent dans la conversation : le sujet demandé et quelques précisions au besoin.

      Méthode :
      1) Comprends l'intention : déduis les éléments les plus utiles à mémoriser à partir du sujet demandé, du niveau de profondeur, et du nombre de questions souhaité.
      2) Pour rappel, tu génères 100 cards au maximum.
      3) Génère #{nb_cards} cards (question/réponse).
      4) Ne crée pas de code ou autre élément, propose juste les questions/réponses.
      5) Ne donne aucune explication, aucun commentaire, aucune introduction. Uniquement les cards.

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
