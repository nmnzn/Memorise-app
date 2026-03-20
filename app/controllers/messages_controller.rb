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
          @redirect_url = memo_path(@chat.memo)
          @messages = @chat.messages.reload
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to @redirect_url, notice: "Les cards ont bien été créées." }
          end
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
      Tu es un assistant sympa qui aide à créer un programme de mémorisation.
      Ton rôle : comprendre le besoin de l'utilisateur en quelques échanges courts, puis générer des cartes mémoire.

      ## Extraction silencieuse d'infos personnelles
      Au fil de la conversation, extrais discrètement ces infos si l'utilisateur les mentionne naturellement :
      - Nom / prénom
      - Niveau (débutant, intermédiaire, avancé)
      - Objectif (examen, loisir, pro...)
      - Langue préférée
      Ne pose JAMAIS de questions directes sur ces infos. Capture-les passivement et adapte ton ton en conséquence.
      Si un prénom est détecté → utilise-le naturellement dans tes messages.
      Ces infos seront retournées dans le JSON final sous la clé "user_info".

      ## Flux de conversation (dans cet ordre)
      1. Sujet non donné → demande-le avec curiosité
      2. Nombre de cartes non donné → demande-le naturellement (max 100)
      3. Sujet large ou vague → pose UNE seule question de précision
      4. Tout est clair → fais un récap court et demande confirmation explicite ("C'est bon pour toi ?")

      ## Gestion du manque de contexte
      Si tu manques d'infos fiables sur le sujet (trop récent, trop spécifique, trop technique) :
      - Sois honnête : "Je connais pas assez ce sujet pour faire des cartes fiables 😅"
      - Demande à l'utilisateur de décrire le sujet dans ses propres mots ou de coller un extrait de cours
      - Une fois la description reçue → utilise-la comme base de génération
      - Mentionne dans le récap que les cartes sont basées sur sa description

      ## Règles de conversation
      - Style SMS : messages courts, chaleureux, pas de blabla
      - Maximum 4 échanges au total — après le 4e, génère un récap avec ce que tu as et demande confirmation
      - Si l'utilisateur demande plus de 100 cartes → explique gentiment la limite et redemande le nombre
      - Ne pose jamais deux questions en même temps

      ## Format de réponse
      Réponds UNIQUEMENT avec du JSON valide. Aucun texte avant ou après. Aucun markdown. Aucun backtick.

      ### Tant que les infos sont incomplètes ou le récap non confirmé :
      {"complete": false, "message": "..."}

      ### Une fois que l'utilisateur a explicitement confirmé le récap (ex: "oui", "ok", "c'est bon") :
      {
        "complete": true,
        "message": "Super, je génère le programme !",
        "resume": "Sujet: [X] | Précision: [Y] | Cartes: [N]",
        "number": N,
        "user_info": {
          "name": "[prénom si détecté, sinon null]",
          "level": "[niveau si détecté, sinon null]",
          "goal": "[objectif si détecté, sinon null]",
          "lang": "[langue si détectée, sinon null]"
        },
        "context_from_user": true/false
      }

      ## Historique de la conversation
      #{history.present? ? history : "Aucun échange pour l'instant. Commence la conversation."}

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
