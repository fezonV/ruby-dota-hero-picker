require "test_helper"

class UiKitControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get ui_kit_path
    assert_redirected_to new_session_path
  end

  test "shows the component catalogue with an explicit demo notice" do
    post session_path, params: { email: users(:one).email, password: "password" }
    get ui_kit_path

    assert_response :success
    assert_select "h1", "UI Kit"
    assert_select ".kit-disclaimer", text: /не сохраняется/
    assert_select ".hero-option", count: 3
    assert_select ".team-slot", count: 5
  end
end
