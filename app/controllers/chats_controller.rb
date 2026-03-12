class ChatsController < ApplicationController

  def new
    @chat = Chat.new
    @memo = Memo.find(params[:memo_id])
    @volume_collection = Chat.volume_collection
    @profondeur_collection = Chat.profondeur_collection
  end

  def create
    raise
    @volume_collection = Chat.volume_collection
    @profondeur_collection = Chat.profondeur_collection

    @memo = Memo.new(memo_params)
    @memo.user = current_user

    @volume = volume_for_system_prompt(params[:memo][:volume])
    @profondeur = profondeur_for_system_prompt(params[:memo][:profondeur])

    @system_prompt = system_prompt(@volume, @profondeur)

    if @memo.save
      llm_cards = generate_cards_with_llm(@system_prompt, @memo.prompt)

      llm_cards.each do |card_data|
        @memo.cards.create!(
          ask: card_data["question"],
          answer: card_data["answer"]
        )
      end

      redirect_to memo_path(@memo), notice: "Le mémo a bien été créé."
    else
      render :new, status: :unprocessable_entity
    end

  rescue JSON::ParserError
    @memo.destroy if @memo.persisted?
    flash.now[:alert] = "Le format retourné par le LLM est invalide."
    render :new, status: :unprocessable_entity
  end
end
