require "application_system_test_case"

class LiveDraftsTest < ApplicationSystemTestCase
  test "two pages keep their own catalogue state while picks sync and a reconnected page catches up" do
    visit new_session_path
    set_field "Email", users(:one).email
    set_field "Пароль", "password"
    submit_form "Войти"
    assert_selector "h1", text: "Aegis Draft"

    visit draft_path(drafts(:one))
    assert_selector "turbo-cable-stream-source[connected]", visible: :all
    sender = current_window
    receiver = open_new_window
    within_window(receiver) do
      visit draft_path(drafts(:one), team: "enemy")
      assert_selector "turbo-cable-stream-source[connected]", visible: :all
      set_field "Поиск по имени или роли", "Lina"
      assert_button "Добавить Lina"
      assert_no_button "Добавить Axe"
    end

    within_window(sender) do
      submit_form "Добавить Axe"
      assert_selector "#team-ally .team-count", text: "1 / 5"
    end
    within_window(receiver) do
      assert_selector "#team-ally .team-slot:first-child strong", text: "Axe"
      assert_field "Поиск по имени или роли", with: "Lina"
      assert_selector "#catalogue [data-hero-search-target=hero]", count: 1
      assert_selector ".team-switch [aria-current=true]", text: "Противники"
      submit_form "Добавить Lina"
      assert_selector "#team-enemy .team-count", text: "1 / 5"
    end
    within_window(sender) do
      assert_selector "#team-enemy .team-slot:first-child strong", text: "Lina"
      submit_form "Удалить Axe"
      assert_selector "#team-ally .team-count", text: "0 / 5"
    end

    within_window(receiver) do
      assert_selector "#team-ally .team-count", text: "0 / 5"
      page.execute_script(<<~JS)
        return import('@hotwired/turbo-rails').then(async ({ cable }) => {
          window.receiverConsumer = await cable.getConsumer()
          window.receiverConsumer.disconnect()
        })
      JS
      assert_no_selector "turbo-cable-stream-source[connected]", visible: :all
    end
    within_window(sender) do
      submit_form "Добавить Juggernaut"
      assert_selector "#team-ally .team-count", text: "1 / 5"
    end
    within_window(receiver) do
      assert_selector "#team-ally .team-count", text: "0 / 5"
      page.execute_script("window.receiverConsumer.connect()")
      assert_selector "turbo-cable-stream-source[connected]", visible: :all
      assert_selector "#team-ally .team-slot:first-child strong", text: "Juggernaut"
      assert_field "Поиск по имени или роли", with: "Lina"
      assert_selector "#catalogue [data-hero-search-target=hero]", count: 1
    end
    within_window(sender) do
      submit_form "Выйти"
      assert_selector "h1", text: "Вход в аккаунт"
    end
    within_window(receiver) { assert_no_selector "turbo-cable-stream-source[connected]", visible: :all }
    receiver.close
  end

  private

  def set_field(label, value)
    page.execute_script(<<~JS, find_field(label), value)
      arguments[0].value = arguments[1]
      arguments[0].dispatchEvent(new Event('input', { bubbles: true }))
    JS
  end

  def submit_form(button)
    # Submit the actual form once; assertions wait for the HTTP and WebSocket results.
    form = find_button(button, exact: true).find(:xpath, "ancestor::form")
    page.execute_script("arguments[0].requestSubmit()", form)
  end
end
