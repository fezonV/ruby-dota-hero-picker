class SessionsController < ApplicationController
  before_action :require_authentication, only: :show

  def new
  end

  def create
    @email = params[:email].to_s.strip.downcase
    unless @email.match?(User::EMAIL_FORMAT)
      flash.now[:alert] = "Введите корректный email"
      return render :new, status: :unprocessable_entity
    end

    user = User.find_by(email: @email)

    unless user
      flash.now[:alert] = "Почта не зарегистрирована"
      return render :new, status: :unprocessable_entity
    end

    if user.authenticate(params[:password].to_s)
      disconnect_live_connections
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
    disconnect_live_connections
    reset_session
    redirect_to new_session_path, notice: "Вы вышли из аккаунта"
  end

  private

  def disconnect_live_connections
    return unless current_user

    ActionCable.server.remote_connections.where(current_user: current_user, cable_session_id: session.id.to_s)
      .disconnect(reconnect: false)
  end
end
