class MemoSharesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo
  before_action :authorize_share_access!, only: [:create]
  before_action :authorize_owner!, only: [:destroy]

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if email.blank?
      redirect_to memo_path(@memo), alert: "Veuillez renseigner un email."
      return
    end

    if user.nil?
      redirect_to memo_path(@memo), alert: "Aucun utilisateur trouvé avec cet email."
      return
    end

    if user == current_user
      redirect_to memo_path(@memo), alert: "Vous êtes déjà propriétaire de ce mémo."
      return
    end

    memo_share = MemoShare.new(memo: @memo, user: user)

    if memo_share.save
      @memo.cards.find_each do |card|
        Answer.find_or_create_by!(card: card, user: user) do |answer|
          answer.value = false
          answer.score = 0.0 if answer.respond_to?(:score)
        end
      end

      redirect_to memo_path(@memo), notice: "#{user.email} a maintenant accès à ce mémo."
    else
      redirect_to memo_path(@memo), alert: "Ce mémo est déjà partagé avec cet utilisateur."
    end
  end

  def destroy
    memo_share = @memo.memo_shares.find(params[:id])
    shared_user_email = memo_share.user.email
    memo_share.destroy

    redirect_to memo_path(@memo), notice: "Le partage avec #{shared_user_email} a été supprimé."
  end

  private

  def set_memo
    @memo = Memo.find(params[:memo_id])
  end

  def authorize_share_access!
    return if @memo.user == current_user || @memo.is_public?

    redirect_to memos_path, alert: "Accès non autorisé."
  end

  def authorize_owner!
    redirect_to memos_path, alert: "Accès non autorisé." unless @memo.user == current_user
  end
end
