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
      Tu es un assistant pour générer un programme de mémorisation. Ton rôle est de questionner l'utilisateur
      sur son besoin, et reformuler ce que tu as compris en conclusion. Tu dois avoir suffisamment d'information
      sur le sujet à mémoriser et connaître le nombre de cards à générer (maximum 100 cards, si l'utilisateur demande plus, alors dis lui que tu peux générer 100 cards au maximum,#{' '}
      et redemande lui combien il en veut finalement). Une fois que tu as toutes les informations, reformule
      ce que tu as compris à l'utilisateur pour lui demander son accord.
      Fais des messages courts de quelques mots uniquement, comme des SMS. N'hésite pas à demander du complément d'information si pertinent selon le sujet,#{' '}
      mais limite le durée de l'échange au maximum (idéalement 3-4 échanges).
      Au final on aura juste besoin de retenir le sujet à mémoriser en quelques lignes, quelques spécificités si pertinentes, et le nombre de questions à mémoriser.

      Voici l'historique des messages échangés (user = l'utilisateur et assistant = tes réponses précédentes) : #{history}

      Réponds UNIQUEMENT avec un objet JSON valide, sans markdown, sans balises code, sans texte autour.
      Le format exact est :
      {"complete": false, "message": "ta réponse"}

      La clé "complete" vaut false tant que tu n'as pas toutes les informations, et true quand tu es prêt à générer le programme ET que l'utilisateur#{' '}
      a donné son accord après ta reformulation.
      Lorsque complete est true, le message sera "Super, je génère le programme de mémorisation !".
      UNIQUEMEMENT lorsque "complete" vaut true, tu peux résumer (afin qu'un LLM puisse générer des questions/réponses)#{' '}
      le besoin de l'utilisation dans la clé "resume", SINON la clé "resume" reste une string vide.
      ALORS, tu pourras également donner à la clé "number", le nombre de questions que l'utilisateur souhaite, SINON "number" reste vide.
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
