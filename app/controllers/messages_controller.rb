class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    @message = Message.new(content: message_params[:content], role: "user", chat: @chat)
    if @message.save
      @volume_collection = Message.volume_collection
      @profondeur_collection = Message.profondeur_collection

      @volume = volume_for_system_prompt(message_params[:volume])
      @profondeur = profondeur_for_system_prompt(message_params[:profondeur])

      @system_prompt = system_prompt(@volume, @profondeur)

      llm_cards = generate_cards_with_llm(@system_prompt, @message.content)

      llm_cards.each do |card_data|
        @chat.memo.cards.create!(
          ask: card_data["question"],
          answer: card_data["answer"]
        )
      end

      redirect_to @chat.memo
    else
      @message = Message.new
      redirect_to @chat, notice: "veuillez recommencer"
    end
  end


  private

  def message_params
    params.require(:message).permit(:content, :volume, :profondeur)
  end

  def generate_cards_with_llm(system_prompt, user_prompt)
    begin
      response = RubyLLM.chat.with_instructions(system_prompt).ask(user_prompt).content
      JSON.parse(response)
    rescue
      redirect_to @chat, notice: "Veuillez réessayer de générer vos cards"
    end
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
    when @volume_collection[0]
      "5"
    when @volume_collection[1]
      "10"
    else
      "1"
    end
  end

  def profondeur_for_system_prompt(profondeur)
    case profondeur
    when @profondeur_collection[0]
      "les grandes lignes/les éléments clés à savoir/macro/grands concepts"
    when @profondeur_collection[1]
      "des éléments spécifiques, précis, des anecdotes"
    else
      "l'essentiel"
    end
  end
end
