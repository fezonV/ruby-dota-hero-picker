class SessionsController < ApplicationController
  before_action :require_authentication, only: :show

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash.now[:alert] = "Неверный email или пароль"
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Вы вышли из аккаунта"
  end
end
