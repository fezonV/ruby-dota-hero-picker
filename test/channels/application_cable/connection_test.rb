require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "identifies the user and browser session from the existing login session" do
    connect session: { user_id: users(:one).id, session_id: "first-browser" }

    assert_equal users(:one), connection.current_user
    assert_equal "first-browser", connection.cable_session_id
  end

  test "rejects guests and sessions whose user no longer exists" do
    assert_reject_connection { connect }
    assert_reject_connection { connect session: { user_id: -1 } }
  end
end
