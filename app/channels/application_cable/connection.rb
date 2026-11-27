module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :cable_session_id

    def connect
      self.current_user = User.find_by(id: request.session[:user_id])
      reject_unauthorized_connection unless current_user
      self.cable_session_id = request.session[:session_id].to_s
    end
  end
end
