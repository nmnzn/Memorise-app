class MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: [:show, :edit, :update, :destroy, :toggle_visibility]
  before_action :authorize_owner!, only: [:edit, :update, :destroy, :toggle_visibility]

  def index
    @memos = current_user.accessible_memos
  end

  def show
    @cards = @memo.cards
  end

  def new
    @memo = Memo.new
  end

  def create
    @memo = Memo.new(memo_params)
    @memo.user = current_user

    if @memo.save
      redirect_to memo_path(@memo), notice: "Le mémo a bien été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @memo.update(memo_params)
      redirect_to memo_path(@memo)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    redirect_to memos_path
  end

  def toggle_visibility
    @memo.update!(is_public: !@memo.is_public?)

    notice_message =
      if @memo.is_public?
        "Le mémo est maintenant public."
      else
        "Le mémo est maintenant privé."
      end

    redirect_back fallback_location: memo_path(@memo), notice: notice_message
  end

  private

  def set_memo
    @memo = current_user.accessible_memos.find(params[:id])
  end

  def authorize_owner!
    return if @memo.user == current_user

    redirect_to memo_path(@memo), alert: "Seul le propriétaire peut modifier ce mémo."
  end

  def memo_params
    params.require(:memo).permit(:name)
  end

  def generate_cards_with_llm(system_prompt, user_prompt)
    response = RubyLLM.chat.with_instructions(system_prompt).ask(user_prompt).content
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
