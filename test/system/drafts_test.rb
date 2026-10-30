require "application_system_test_case"

class DraftsTest < ApplicationSystemTestCase
  test "search, choose a side, apply a recommendation and keep the draft after reload and a new login" do
    sign_in
    click_link "Мои драфты"
    click_link "Создать драфт"
    fill_in "Название драфта", with: "Браузерный состав"
    click_button "Создать драфт"
    assert_text "Драфт создан и сохранён"
    draft = users(:one).drafts.find_by!(title: "Браузерный состав")

    within "#catalogue" do
      fill_in "Поиск по имени или роли", with: "несуществующий герой"
      assert_text "Ничего не найдено"
      fill_in "Поиск по имени или роли", with: "ИНИЦИАЦИЯ"
      assert_button "Добавить Axe"
      assert_no_button "Добавить Lina"
      fill_in "Поиск по имени или роли", with: "aXe"
      assert_button "Добавить Axe"
      find("#hero-search").send_keys(:tab, :enter)
    end
    assert_text "Axe добавлен. Состав сохранён."
    within "#team-ally" do
      assert_text "Axe"
      assert_text "1 / 5"
    end
    within "#catalogue" do
      assert_button "Добавить Axe", disabled: true
      click_link "Противники"
      fill_in "Поиск по имени или роли", with: "Juggernaut"
      click_button "Добавить Juggernaut"
    end
    assert_text "Juggernaut добавлен. Состав сохранён."
    assert_selector ".team-switch a[aria-current=true]", text: "Противники"
    within("#team-enemy") { assert_text "Juggernaut" }

    recommended = draft.recommendations.first[:hero]
    within ".recommendation[data-hero-id='#{recommended.id}']" do
      assert_text recommended.name
      assert_selector ".recommendation-reasons li"
      click_button "Добавить в мою команду"
    end
    assert_text "#{recommended.name} добавлен. Состав сохранён."
    within("#team-ally") { assert_text recommended.name }
    assert_selector ".team-switch a[aria-current=true]", text: "Противники"
    assert_equal "ally", draft.draft_picks.find_by!(hero: recommended).team

    page.refresh
    within("#team-ally") { assert_text recommended.name }
    within("#team-enemy") { assert_text "Juggernaut" }
    click_button "Выйти"
    sign_in
    click_link "Мои драфты"
    click_link "Браузерный состав"
    within("#team-ally") { click_button "Удалить #{recommended.name}" }
    assert_text "Герой удалён. Состав сохранён."
    within("#team-ally") { assert_no_text recommended.name }
    assert_selector ".recommendation[data-hero-id='#{recommended.id}']"
    assert_equal [ [ heroes(:axe).id, "ally", 1 ], [ heroes(:juggernaut).id, "enemy", 1 ] ],
      draft.draft_picks.order(:team, :position).pluck(:hero_id, :team, :position)
  end

  test "draft pages fit desktop and phone with readable empty error search and complete states" do
    sign_in
    users(:one).drafts.destroy_all
    [ [ "desktop", 1440, 900 ], [ "mobile", 390, 844 ] ].each do |device, width, height|
      resize_viewport(width, height)
      visit root_path
      capture("#{device}-home")
      click_link "Мои драфты"
      assert_text "Пока нет драфтов"
      capture("#{device}-drafts-empty")
      click_link "Создать драфт"
      capture("#{device}-new")
      fill_in "Название драфта", with: " "
      click_button "Создать драфт"
      assert_selector "[role=alert]", text: "Название не может быть пустым"
      capture("#{device}-title-error")
      fill_in "Название драфта", with: "Состав для проверки"
      click_button "Создать драфт"
      assert_text "Драфт создан и сохранён"
      capture("#{device}-editor-empty")
      within "#catalogue" do
        click_link "Противники"
        click_button "Добавить Axe"
      end
      assert_text "Axe добавлен. Состав сохранён."
      within("#recommendations .recommendation:first-child") { click_button "Добавить в мою команду" }
      assert_selector "#team-ally .team-count", text: "1 / 5"
      capture("#{device}-editor-partial")
      capture("#{device}-editor-partial-repeat") if ENV["VISUAL_QA"]
      within "#catalogue" do
        fill_in "Поиск по имени или роли", with: "никакого героя"
        assert_text "Ничего не найдено"
      end
      capture("#{device}-search-empty")
      within "#catalogue" do
        fill_in "Поиск по имени или роли", with: ""
        click_link "Моя команда"
      end
      assert_selector ".team-switch a[aria-current=true]", text: "Моя команда"
      4.times do |index|
        within("#recommendations .recommendation:first-child") { click_button "Добавить в мою команду" }
        assert_selector "#team-ally .team-count", text: "#{index + 2} / 5"
      end
      assert_text "Команда собрана"
      capture("#{device}-editor-full")
      click_link "Мои драфты"
      assert_text "Моя команда: 5 / 5"
      capture("#{device}-drafts-saved")
      # A stale page can submit a hero already chosen in another browser tab.
      within(".draft-list") { click_link "Состав для проверки" }
      within "#catalogue" do
        click_link "Противники"
        assert_button "Добавить Windranger"
      end
      stale_pick = users(:one).drafts.find_by!(title: "Состав для проверки")
        .add_pick(hero_id: heroes(:windranger).id, team: "enemy")
      assert stale_pick.persisted?
      within("#catalogue") { click_button "Добавить Windranger" }
      assert_selector "[role=alert]", text: /уже выбран/
      capture("#{device}-pick-error")
      users(:one).drafts.reload.destroy_all
    end

    Hero.delete_all
    draft = users(:one).drafts.create!(title: "Пустой каталог")
    [ [ "desktop", 1440, 900 ], [ "mobile", 390, 844 ] ].each do |device, width, height|
      resize_viewport(width, height)
      visit draft_path(draft)
      assert_text "Каталог пока пуст"
      capture("#{device}-catalogue-empty")
    end
  end

  private

  def resize_viewport(width, height)
    page.current_window.resize_to(width, height)
    viewport = page.evaluate_script("({ width: window.innerWidth, height: window.innerHeight })")
    page.current_window.resize_to(width * 2 - viewport["width"], height * 2 - viewport["height"])
    assert_equal [ width, height ], page.evaluate_script("[window.innerWidth, window.innerHeight]")
  end

  def sign_in
    visit new_session_path
    fill_in "Email", with: users(:one).email
    fill_in "Пароль", with: "password"
    click_button "Войти"
    assert_selector "h1", text: "Aegis Draft"
  end

  def capture(name)
    assert_no_selector ".turbo-progress-bar", visible: :all
    assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth"), "Horizontal overflow on #{name}"
    return unless ENV["VISUAL_QA"]

    page.driver.browser.execute_async_script("const done = arguments[0]; document.fonts.ready.then(() => done(true))")
    dimensions = page.evaluate_script("({ width: window.innerWidth, height: window.innerHeight, pageHeight: document.documentElement.scrollHeight })")
    FileUtils.mkdir_p(Rails.root.join("tmp/visual-qa"))
    screenshot = page.driver.browser.execute_cdp("Page.captureScreenshot",
      captureBeyondViewport: true, clip: { x: 0, y: 0, width: dimensions["width"], height: dimensions["pageHeight"], scale: 1 })
    File.binwrite(Rails.root.join("tmp/visual-qa/#{name}.png"), Base64.decode64(screenshot.fetch("data")))
    File.write(Rails.root.join("tmp/visual-qa/#{name}.json"), JSON.pretty_generate(dimensions))
  end
end
