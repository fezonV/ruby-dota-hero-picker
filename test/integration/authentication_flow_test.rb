require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "user registers, logs in, visits a protected page, and logs out" do
    get root_path
    assert_redirected_to new_session_path

    get new_registration_path
    assert_response :success

    assert_difference("User.count", 1) do
      post registration_path, params: {
        user: {
          email: "journey@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to registration_created_path
    follow_redirect!
    assert_select "a[href=?]", new_session_path

    post session_path, params: {
      email: "JOURNEY@EXAMPLE.COM",
      password: "password"
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Aegis Draft"
    assert_select "p", text: /journey@example.com/

    delete session_path
    assert_redirected_to new_session_path

    get root_path
    assert_redirected_to new_session_path
  end
end
