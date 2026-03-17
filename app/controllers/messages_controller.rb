class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])

    @message = @chat.messages.build(content: message_params[:content])

    volume = params[:message][:volume]
    profondeur = params[:message][:profondeur]

    if @message.content.blank?
      @message.errors.add(:content, "Le sujet ne peut pas être vide.")
      render "chats/show", status: :unprocessable_entity
      return
    end

    system_prompt_text = system_prompt(
      volume_for_system_prompt(volume),
      profondeur_for_system_prompt(profondeur)
    )

    if @message.save
      llm_cards = generate_cards_with_llm(system_prompt_text, @message.content)

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
    else
      render "chats/show", status: :unprocessable_entity
    end
  rescue JSON::ParserError
    @message.errors.add(:base, "La réponse de l'IA est invalide.")
    render "chats/show", status: :unprocessable_entity
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def generate_cards_with_llm(system_prompt, user_prompt)
    response = RubyLLM.chat(model: "gpt-4o-mini").with_instructions(system_prompt).ask(user_prompt).content
    JSON.parse(response)
  end

  def system_prompt(volume, profondeur)
    <<~PROMPT
      Tu es Memorise, une application faite pour aider l'utilisateur à se souvenir des choses, simplement et naturellement. Ton ton : clair, concis, utile. Pas de blabla. Pas de texte inutile.

      Ton objectif : proposer des cards (question et réponse associée) pertinentes pour l'utilisateur, en te basant uniquement sur ce qui est explicitement présent dans la conversation : le sujet demandé (le sujet), le niveau de mémorisation souhaité (le nombre de questions = le volume de connaissance), le type de connaissances voulu si précisé (la profondeur des questions).

      Méthode :
      1) Comprends l'intention : déduis les éléments les plus utiles à mémoriser à partir du sujet demandé, du niveau de profondeur, et du nombre de questions souhaité.
      2) Si l'utilisateur précise un nombre de questions, respecte-le, tant qu'il est compris entre 1 et 10.
      3) Génère #{volume} cards (question/réponse).
      4) Type de questions : #{profondeur}.
      5) Si la demande est floue : ne pose pas de questions, propose quand même des cards cohérentes avec le sujet.
      6) Ne crée pas de code ou autre élément, propose juste les questions/réponses.
      7) Ne donne aucune explication, aucun commentaire, aucune introduction. Uniquement les cards.

      Format de réponse obligatoire : un array JSON composé d'objets, avec exactement les clés "question" et "answer".

      Exemple :
      [
        { "question": "Question 1", "answer": "Réponse 1" },
        { "question": "Question 2", "answer": "Réponse 2" },
        { "question": "Question 3", "answer": "Réponse 3" }
      ]
    PROMPT
  end

  def volume_for_system_prompt(volume)
    case volume
    when "Synthétique"
      "5"
    when "Large"
      "10"
    else
      "1"
    end
  end

  def profondeur_for_system_prompt(profondeur)
    case profondeur
    when "Grandes lignes"
      "les grandes lignes/les éléments clés à savoir/macro/grands concepts"
    when "Approfondie"
      "des éléments spécifiques, précis, des anecdotes"
    else
      "l'essentiel"
    end
  end
end
