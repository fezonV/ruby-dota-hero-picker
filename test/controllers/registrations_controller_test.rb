require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "shows the registration form" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Создать аккаунт"
    assert_select "form[action=?]", registration_path
  end

  test "redirects unauthenticated users from the root page" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "creates a user with valid data" do
    assert_difference("User.count", 1) do
      post registration_path, params: {
        user: {
          email: "new-user@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to registration_created_path
    follow_redirect!

    assert_response :success
    assert_select "h1", "Аккаунт создан"
  end

  test "does not create a user with invalid data" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email: "invalid-email",
          password: "password",
          password_confirmation: "different-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert]"
  end

  test "requires password confirmation" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email: "without-confirmation@example.com",
          password: "password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert]", text: /Подтверждение пароля/
  end
end
