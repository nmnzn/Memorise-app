class MemosController < ApplicationController
  def index
    @memos = current_user.memos
  end

  def show
    @memo = Memo.find(params[:id])
    @cards = @memo.cards
  end

  def new
    @memo = Memo.new
    @volume_collection = Memo.volume_collection
    @profondeur_collection = Memo.profondeur_collection
  end

  def create
    @volume_collection = Memo.volume_collection
    @profondeur_collection = Memo.profondeur_collection

    @memo = Memo.new(memo_params)
    @memo.user = current_user

    @volume = volume_for_system_prompt(params[:memo][:volume])
    @profondeur = profondeur_for_system_prompt(params[:memo][:profondeur])

    @system_prompt = system_prompt(@volume, @profondeur)
    @user_prompt = @memo.prompt

    if @memo.save
      # call LLM avec @memo.prompt pour recevoir les questions/réponses
      @llm_response = call_llm_for_questions_answers(@system_prompt, @user_prompt)
      # méthode pour créer des cards avec le retour du LLM - en attente
      raise
      redirect_to memo_path(@memo), notice: "Le mémo a bien été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @memo = Memo.find(params[:id])
    @memo.destroy
    redirect_to memos_path
  end

   def edit
     @memo = Memo.find(params[:id])
   end

   def update
    @memo = Memo.find(params[:id])
    if @memo.update(memo_params)
      redirect_to memo_path(@memo)
    else
      render :edit, status: :unprocessable_entity
    end
   end



  private

  def memo_params
    params.require(:memo).permit(:name, :prompt)
  end

  def system_prompt(volume, profondeur)
    return "Tu es Memorise, une application faite pour aider l’utilisateur à se souvenir des choses, simplement et naturellement. Ton ton : clair, concis, utile. Pas de blabla. Pas de texte inutile.
      end

      Ton objectif : proposer des cards (question et réponse associée) pertinentes pour l’utilisateur, en te basant uniquement sur ce qui est explicitement présent dans la conversation : le sujet demandé (le sujet), le niveau de mémorisation souhaité (le nombre de questions = le volume de connaissance), le type de connaissances voulu si précisé (la profondeur des questions).

      Méthode :
      1) Comprends l’intention : déduis les éléments les plus utiles à mémoriser à partir du sujet demandé, du niveau de profondeur, et du nombre de questions souhaité.
      3) Si l’utilisateur précise un nombre de questions, respecte-le, tant qu’il est compris entre 1 et 10.
      4) Génère #{volume} cards (question/réponse)
      5) Type de questions : #{profondeur}
      6) Si la demande est floue : ne pose pas de questions, propose quand même des cards cohérentes avec le sujet.
      7) Ne crée pas de code ou autre élément, propose juste les questions/réponses.
      8) Ne donne aucune explication, aucun commentaire, aucune introduction. Uniquement les cards (pour rappel une card est composée d'une question et d'une réponse).

      Format de réponse (obligatoire, indiscutable, et systématique, avec un texte clair uniquement) : un array composé de hashs, où chaque hash comprend une card (question et réponse).
      exemple :
      [
        { 'question': 'Question 1', 'answer': 'Réponse 1' },
        { 'question': 'Question 2', 'answer': 'Réponse 2' },
        { 'question': 'Question 3', 'answer': 'Réponse 3' }
      ]"
  end

  def call_llm_for_questions_answers(system_prompt, user_prompt)
    response = RubyLLM.chat.with_instructions(system_prompt).ask(user_prompt).content
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
      "des éléments spécifiques, précis, des anecdoques"
    else
      "l'essentiel"
    end
  end
end
