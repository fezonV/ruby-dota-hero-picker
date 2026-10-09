class HomeController < ApplicationController
  before_action :open_login_for_guests

  def index
  end

  private

  def open_login_for_guests
    redirect_to new_session_path unless current_user
  end
end
