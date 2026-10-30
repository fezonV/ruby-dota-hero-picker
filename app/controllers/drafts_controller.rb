class DraftsController < ApplicationController
  before_action :require_authentication

  def index
    @drafts = current_user.drafts.includes(:draft_picks).order(created_at: :desc, id: :desc)
  end

  def new
    @draft = current_user.drafts.build
  end

  def create
    @draft = current_user.drafts.build(params.require(:draft).permit(:title))
    if @draft.save
      redirect_to draft_path(@draft), status: :see_other, notice: "Драфт создан и сохранён."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @draft = current_user.drafts.find(params[:id])
    @selected_team = params[:team] == "enemy" ? "enemy" : "ally"
    @heroes = Hero.order(:name)
    @picks = @draft.draft_picks.includes(:hero).order(:position).to_a
    @recommendations = @draft.recommendations
  end
end
