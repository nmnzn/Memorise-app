class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    return unless user_signed_in?

    @favorite_memos = current_user.memos.includes(:cards).where(favorite: true)

    @total_cards_count = current_user.memos.joins(:cards).count
    @known_cards_count = current_user.answers.where(value: true).count

    @progress_percent =
      if @total_cards_count.zero?
        0
      else
        ((@known_cards_count.to_f / @total_cards_count) * 100).round
      end
  end
end
