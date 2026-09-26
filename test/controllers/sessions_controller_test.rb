require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "shows the login form" do
    get new_session_path

    assert_response :success
    assert_select "h1", "Войти в аккаунт"
    assert_select "form[action=?]", session_path
    assert_select "nav a[href=?]", new_registration_path, text: "Регистрация"
  end

  test "logs in with valid credentials" do
    post session_path, params: {
      email: users(:one).email,
      password: "password"
    }

    assert_redirected_to root_path

    get session_path
    assert_response :success
    assert_select "p", users(:one).email
  end

  test "rejects invalid credentials" do
    post session_path, params: {
      email: users(:one).email,
      password: "incorrect"
    }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "Неверный email или пароль"
    assert_select "input[name=email][value=?]", users(:one).email
    assert_select "input[name=password]:not([value])"
  end

  test "normalizes email before login" do
    post session_path, params: {
      email: "  #{users(:one).email.upcase}  ",
      password: "password"
    }

    assert_redirected_to root_path
  end

  test "requires authentication to show the account" do
    get session_path

    assert_redirected_to new_session_path
  end

  test "logs out the current user" do
    post session_path, params: {
      email: users(:one).email,
      password: "password"
    }

    delete session_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "[role=status]", "Вы вышли из аккаунта"

    get session_path
    assert_redirected_to new_session_path
  end
end
