class DraftPicksController < ApplicationController
  before_action :require_authentication
  before_action :find_draft

  def create
    @pick = @draft.add_pick(params.require(:draft_pick).permit(:hero_id, :team))
    if @pick.persisted?
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "#{@pick.hero.name} добавлен. Состав сохранён."
          render :change
        end
        format.html do
          redirect_to draft_path(@draft, team: @selected_team, anchor: "catalogue"), status: :see_other,
            notice: "#{@pick.hero.name} добавлен. Состав сохранён."
        end
      end
    else
      @heroes = Hero.order(:name)
      @picks = @draft.draft_picks.includes(:hero).order(:position).to_a
      @recommendations = @draft.recommendations
      respond_to do |format|
        format.turbo_stream { render :change, status: :unprocessable_entity }
        format.html { render "drafts/show", status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @draft.with_lock do
      @draft.draft_picks.find(params[:id]).destroy!
    end
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Герой удалён. Состав сохранён."
        render :change
      end
      format.html do
        redirect_to draft_path(@draft, team: @selected_team), status: :see_other,
          notice: "Герой удалён. Состав сохранён."
      end
    end
  end

  private

  def find_draft
    @draft = current_user.drafts.find(params[:draft_id])
    @selected_team = params[:catalog_team] == "enemy" ? "enemy" : "ally"
  end
end
