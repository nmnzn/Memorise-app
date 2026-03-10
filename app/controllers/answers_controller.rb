class AnswersController < ApplicationController
  def update
    @answer = Answer.find(params[:id])
    @answer.update!(value: params[:value] == "true")
    redirect_to play_path
  end
end
