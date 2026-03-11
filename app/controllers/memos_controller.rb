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
      redirect_to memos_path, notice: "Le mémo a bien été créé."
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

  SYSTEM_PROMPT = "Génère des questions et des réponses associées sur le sujet suivant : "

  private

  def memo_params
    params.require(:memo).permit(:name, :prompt)
  end

  def call_llm_for_questions_answers(prompt)
    response = RubyLLM.chat.ask("#{SYSTEM_PROMPT}#{prompt}").content
  end

end
