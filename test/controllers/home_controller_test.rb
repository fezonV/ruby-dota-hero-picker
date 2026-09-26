require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to login" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "shows the home page to an authenticated user" do
    post session_path, params: {
      email: users(:one).email,
      password: "password"
    }

    get root_path

    assert_response :success
    assert_select "h1", "Aegis Draft"
    assert_select "p", text: /#{Regexp.escape(users(:one).email)}/
    assert_select "nav a[href=?]", session_path, text: "Аккаунт"
    assert_select "nav form[action=?]", session_path
  end
end
