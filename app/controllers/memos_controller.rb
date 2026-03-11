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
  end

  def create
    @memo = Memo.new(memo_params)
    @memo.user = current_user

    if @memo.save
      # call LLM avec @memo.prompt pour recevoir les questions/réponses
      call_llm_for_questions_answers(@memo.prompt)
      # méthode pour créer des cards avec le retour du LLM
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

  SYSTEM_PROMPT = "Tu es Memorise, une application faite pour aider l’utilisateur à se souvenir des choses, simplement et naturellement. Ton ton : clair, concis, utile. Pas de blabla. Pas de texte inutile.

    Ton objectif : proposer des cards (question et réponse associée) pertinentes pour l’utilisateur, en te basant uniquement sur ce qui est explicitement présent dans la conversation : le sujet demandé (le sujet), le niveau de mémorisation souhaité (le nombre de questions = le volume de connaissance), le type de connaissances voulu si précisé (la profondeur des questions).

    Méthode :
    1) Comprends l’intention : déduis les éléments les plus utiles à mémoriser à partir du sujet demandé, du niveau de profondeur, et du nombre de questions souhaité.
    3) Si l’utilisateur précise un nombre de questions, respecte-le, tant qu’il est compris entre 1 et 10.
    4) Si l’utilisateur ne précise pas de nombre de questions, adapte la quantité selon le niveau demandé :
        - léger = 3 cards
        - moyen = 6 cards
        - profond = 10 cards
    5) Si le type de connaissances :
        - grandes lignes = privilégie l’essentiel
        - anecdotes = privilégie les détails marquants et mémorables pour maitriser le sujet dans certains détails
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

  private

  def memo_params
    params.require(:memo).permit(:name, :prompt)
  end

  def call_llm_for_questions_answers(prompt)
    response = RubyLLM.chat.ask("#{SYSTEM_PROMPT}#{prompt}").content
    raise
  end

end
