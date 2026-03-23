class LlmChatJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(chat_id, user_message_id)
    chat = Chat.find(chat_id)
    user_message = Message.find(user_message_id)
    messages = chat.messages.order(:created_at)
    history = build_history(messages)

    hash_response = llm_answering_to_user(user_message.content, history)

    if hash_response["complete"]
      object_with_cards = generate_cards_with_llm(hash_response["resume"], hash_response["number"], history)
      llm_cards = object_with_cards["cards"]

      if llm_cards.is_a?(Array)
        card_count = 0
        llm_cards.each do |card_data|
          next unless card_data.is_a?(Hash)
          question = card_data["question"] || card_data[:question]
          answer   = card_data["answer"]   || card_data[:answer]
          next if question.blank? || answer.blank?
          kind = card_count.odd? ? :qcm : :flip
          chat.memo.cards.create!(ask: question, answer: answer, kind: kind)
          card_count += 1
        end
      end

      Message.create!(content: hash_response["message"], role: "assistant", chat_id: chat.id)

      broadcast_update(chat, "chat_messages", partial: "chats/shared/chat", locals: { messages: chat.messages.reload })
      broadcast_update(chat, "redirect-handler", html: "<div data-controller=\"auto-redirect\" data-auto-redirect-url-value=\"#{memo_path(chat.memo)}\"></div>")
    else
      Message.create!(content: hash_response["message"], role: "assistant", chat_id: chat.id)

      broadcast_update(chat, "chat_messages", partial: "chats/shared/chat", locals: { messages: chat.messages.reload })
      broadcast_update(chat, "message_form", partial: "chats/shared/message_input", locals: { chat: chat, message: Message.new })
    end
  rescue => e
    Rails.logger.error "LlmChatJob failed for chat #{chat_id}: #{e.message}"
    chat = Chat.find_by(id: chat_id)
    return unless chat
    broadcast_update(chat, "message_form", partial: "chats/shared/message_input", locals: { chat: chat, message: Message.new })
    broadcast_update(chat, "chat_messages", partial: "chats/shared/chat", locals: { messages: chat.messages.reload })
  end

  private

  def broadcast_update(chat, target, partial: nil, locals: {}, html: nil)
    if html
      Turbo::StreamsChannel.broadcast_update_to(chat, target: target, html: html)
    else
      rendered = ApplicationController.renderer.render(partial: partial, locals: locals)
      Turbo::StreamsChannel.broadcast_update_to(chat, target: target, html: rendered)
    end
  end

  def build_history(messages)
    messages.map { |m| "Role: #{m.role}, Message: #{m.content} -" }.join
  end

  def llm_answering_to_user(message, history)
    collect_info = <<~PROMPT
    Tu es un assistant sympa qui aide à créer un programme de mémorisation.

    Si le sujet n'est pas encore donné → demande-le avec curiosité.
    Si le nombre de cartes n'est pas donné → demande-le naturellement (max 50, précise le à l'utilisateur s'il en demande plus que 50, sinon ne parle pas de cette limite)
    Si le sujet est large ou vague → pose une petite question de précision
    Si le sujet implique différents niveaux, n'hésite pas à demander son niveau à l'utilisateur, pour que le prochain agent IA responsable du programme prépare des questions avec une difficulté adaptée et pertinente.
    Une fois tout clair et que tu es sûr d'avoir suffisemment d'information pour générer un programme de mémorisation (question/réponses) → fais un court récap avant de lancer la génération ET demande l'accord à l'utlisateur pour générer le programme.

    Quelques règles :
    Messages courts et chaleureux, pas de blabla, style SMS
    Evite trop de redondance dans tes messages sauf lorsque tu récapitules en fin de conversation avant de générer le programme.
    Idéalement, il y a 3-4 échanges, si besoin tu peux étendre légèrement la conversation. L'important est de comprendre le besoin utilisateur et attendre son accord pour lancer la génération de cartes.
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

    RubyLLM.chat.with_schema(output_schema).with_instructions(collect_info).ask(message).content
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
