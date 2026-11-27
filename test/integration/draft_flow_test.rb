require "test_helper"

class DraftFlowTest < ActionDispatch::IntegrationTest
  test "happy path registers builds edits and reopens both saved teams after a new login" do
    email = "draft-journey@example.test"
    get new_registration_path
    assert_response :success
    post registration_path, params: { user: {
      email: email, password: "password", password_confirmation: "password"
    } }
    assert_redirected_to registration_created_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Аккаунт создан"
    assert_select "a[href=?]", new_session_path
    get drafts_path
    assert_redirected_to new_session_path

    sign_in(email)
    follow_redirect!
    assert_response :success
    assert_select "a[href=?]", drafts_path, text: "Мои драфты"
    get drafts_path
    assert_response :success
    assert_select "h2", "Пока нет драфтов"
    assert_select "a[href=?]", new_draft_path
    get new_draft_path
    assert_response :success
    assert_select "label[for=draft_title]", "Название драфта"

    post drafts_path, params: { draft: { title: "  Состав для защиты  " } }
    assert_response :see_other
    draft = response.location.split("/").last
    assert_redirected_to draft_path(draft)
    follow_redirect!
    assert_select "h1", "Состав для защиты"
    assert_select "[role=status]", "Драфт создан и сохранён."
    assert_teams(allies: [], enemies: [])

    add_hero(draft, :juggernaut, "ally")
    assert_teams(allies: %i[juggernaut], enemies: [])
    add_hero(draft, :axe, "ally")
    assert_teams(allies: %i[juggernaut axe], enemies: [])
    %i[centaur tidehunter sniper phantom dazzle].each { |hero| add_hero(draft, hero, "enemy") }
    assert_teams(allies: %i[juggernaut axe], enemies: %i[centaur tidehunter sniper phantom dazzle])

    # Known fixture example: 6 support + 4 control + 2 damage + 1 enemy durability bonus.
    assert_select "#recommendations", text: /Учебная эвристика.*не вероятность победы/m
    assert_select ".recommendation:first-child[data-hero-id=?]", heroes(:maiden).id do
      assert_select "h3", "Crystal Maiden"
      assert_select ".recommendation-heading span", "13 балл."
      assert_equal [
        "Команде нужна поддержка", "Команде нужен контроль", "Команде нужен урон",
        "У противника плотный состав: полезен дополнительный урон"
      ], css_select(".recommendation:first-child .recommendation-reasons li").map(&:text)
      assert_select "form[action=?]", draft_draft_picks_path(draft) do
        assert_select "input[name='draft_pick[hero_id]'][value=?]", heroes(:maiden).id
        assert_select "input[name='draft_pick[team]'][value=ally]"
        assert_select "input[name=catalog_team][value=enemy]"
      end
    end
    assert_select "#catalogue button[aria-label='Добавить Axe'][disabled]"

    add_hero(draft, :maiden, "ally", catalog_team: "enemy")
    assert_select ".team-switch a[aria-current=true]", "Противники"
    assert_teams(allies: %i[juggernaut axe maiden], enemies: %i[centaur tidehunter sniper phantom dazzle])
    remove_hero(:maiden, "ally", catalog_team: "enemy")
    assert_teams(allies: %i[juggernaut axe], enemies: %i[centaur tidehunter sniper phantom dazzle])
    assert_select ".recommendation", minimum: 1
    add_hero(draft, :lion, "ally")
    assert_teams(allies: %i[juggernaut axe lion], enemies: %i[centaur tidehunter sniper phantom dazzle])
    add_hero(draft, :lina, "ally")
    add_hero(draft, :sven, "ally")
    assert_select "#recommendations h3", "Команда собрана"
    assert_select ".recommendation", count: 0
    assert_teams(allies: %i[juggernaut axe lion lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle])

    get drafts_path
    assert_response :success
    assert_select ".draft-list-link", count: 1
    assert_select ".draft-list-link[href=?]", draft_path(draft) do
      assert_select "strong", "Состав для защиты"
      assert_select "span", "Моя команда: 5 / 5 · Противники: 5 / 5"
    end
    get css_select(".draft-list-link").first["href"]
    assert_teams(allies: %i[juggernaut axe lion lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle])
    delete session_path
    assert_redirected_to new_session_path
    get draft_path(draft)
    assert_redirected_to new_session_path

    returning_user = open_session
    sign_in(email, client: returning_user)
    returning_user.get drafts_path
    returning_user.assert_select ".draft-list-link", count: 1
    returning_user.get returning_user.css_select(".draft-list-link").first["href"]
    returning_user.assert_select "h1", "Состав для защиты"
    assert_teams(allies: %i[juggernaut axe lion lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle],
      client: returning_user)
  end

  test "guest is sent to login without changing drafts and can edit after signing in" do
    draft = drafts(:one)
    owner = open_session
    sign_in(users(:one).email, client: owner)
    add_hero(draft, :axe, "ally", client: owner)
    add_hero(draft, :dazzle, "enemy", client: owner)
    delete_path = removal_path(:axe, "ally", client: owner)

    guest = open_session
    [ session_path, drafts_path, new_draft_path, draft_path(draft) ].each do |path|
      guest.get path
      assert_login_required(client: guest)
      owner.get draft_path(draft)
      assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    end
    guest.post drafts_path, params: { draft: { title: "Гостевой" } }
    assert_login_required(client: guest)
    owner.get drafts_path
    owner.assert_select ".draft-list-link", count: 1
    owner.assert_select ".draft-list-link strong", "Первый драфт"

    guest.post draft_draft_picks_path(draft), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
    assert_login_required(client: guest)
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    guest.delete delete_path
    assert_login_required(client: guest)
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)

    sign_in(users(:one).email, client: guest)
    guest.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: guest)
    add_hero(draft, :lina, "ally", client: guest)
    assert_teams(allies: %i[axe lina], enemies: %i[dazzle], client: guest)
    remove_hero(:axe, "ally", client: guest)
    owner.get draft_path(draft)
    assert_teams(allies: [ nil, :lina ], enemies: %i[dazzle], client: owner)
  end

  test "another user cannot read or change a foreign draft and owner can still edit" do
    draft = drafts(:one)
    owner = open_session
    sign_in(users(:one).email, client: owner)
    add_hero(draft, :axe, "ally", client: owner)
    add_hero(draft, :dazzle, "enemy", client: owner)
    delete_path = removal_path(:axe, "ally", client: owner)
    pick_id = delete_path.split("/").last

    other = open_session
    sign_in(users(:two).email, client: other)
    add_hero(drafts(:other), :juggernaut, "ally", client: other)
    other.get drafts_path
    other.assert_response :success
    other.assert_select ".draft-list-link", count: 1
    other.assert_select ".draft-list-link strong", "Чужой драфт"
    other.assert_select ".draft-list-link[href=?]", draft_path(draft), count: 0

    other.get draft_path(draft)
    other.assert_response :not_found
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    other.post draft_draft_picks_path(draft), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
    other.assert_response :not_found
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    other.delete delete_path
    other.assert_response :not_found
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    other.delete draft_draft_pick_path(drafts(:other), pick_id)
    other.assert_response :not_found
    owner.get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: %i[dazzle], client: owner)
    other.get draft_path(drafts(:other))
    assert_teams(allies: %i[juggernaut], enemies: [], client: other)

    owner.get drafts_path
    owner.assert_select ".draft-list-link", count: 1
    owner.assert_select ".draft-list-link strong", "Первый драфт"
    owner.get draft_path(draft)
    add_hero(draft, :lina, "ally", client: owner)
    remove_hero(:axe, "ally", client: owner)
    owner.get draft_path(draft)
    assert_teams(allies: [ nil, :lina ], enemies: %i[dazzle], client: owner)
    other.get draft_path(drafts(:other))
    assert_teams(allies: %i[juggernaut], enemies: [], client: other)
  end

  test "duplicate hero is rejected on either side without changing saved teams" do
    sign_in(users(:one).email)
    draft = drafts(:one)
    add_hero(draft, :axe, "ally")
    add_hero(draft, :dazzle, "enemy")
    %w[ally enemy].each do |team|
      assert_rejected_pick(draft, heroes(:axe).id, team, /уже выбран/)
      assert_teams(allies: %i[axe], enemies: %i[dazzle], status: :unprocessable_entity)
      get draft_path(draft)
      assert_teams(allies: %i[axe], enemies: %i[dazzle])
    end
    add_hero(draft, :lina, "ally")
    add_hero(draft, :juggernaut, "enemy")
    get draft_path(draft)
    assert_teams(allies: %i[axe lina], enemies: %i[dazzle juggernaut])
  end

  test "sixth hero is rejected on either side until the owner frees a slot" do
    sign_in(users(:one).email)
    draft = drafts(:one)
    %i[axe juggernaut maiden lina sven].each { |hero| add_hero(draft, hero, "ally") }
    %i[centaur tidehunter sniper phantom dazzle].each { |hero| add_hero(draft, hero, "enemy") }
    %w[ally enemy].each do |team|
      assert_rejected_pick(draft, heroes(:lion).id, team, /уже пять героев/)
      assert_teams(allies: %i[axe juggernaut maiden lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle],
        status: :unprocessable_entity)
      get draft_path(draft)
      assert_teams(allies: %i[axe juggernaut maiden lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle])
    end

    remove_hero(:maiden, "ally")
    assert_teams(allies: [ :axe, :juggernaut, nil, :lina, :sven ], enemies: %i[centaur tidehunter sniper phantom dazzle])
    assert_select ".recommendation", minimum: 1
    assert_select "#catalogue button[aria-label='Добавить Crystal Maiden']:not([disabled])"
    add_hero(draft, :lion, "ally")
    assert_select "#recommendations h3", "Команда собрана"
    assert_select ".recommendation", count: 0
    get draft_path(draft)
    assert_teams(allies: %i[axe juggernaut lion lina sven], enemies: %i[centaur tidehunter sniper phantom dazzle])

    remove_hero(:sniper, "enemy")
    assert_teams(allies: %i[axe juggernaut lion lina sven], enemies: [ :centaur, :tidehunter, nil, :phantom, :dazzle ])
    add_hero(draft, :windranger, "enemy")
    get draft_path(draft)
    assert_teams(allies: %i[axe juggernaut lion lina sven], enemies: %i[centaur tidehunter windranger phantom dazzle])
  end

  test "missing drafts and picks return 404 and existing drafts remain editable" do
    sign_in(users(:one).email)
    draft = drafts(:one)
    add_hero(draft, :axe, "ally")
    get draft_path(-1)
    assert_response :not_found
    get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: [])
    post draft_draft_picks_path(-1), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
    assert_response :not_found
    get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: [])
    delete draft_draft_pick_path(draft, -1)
    assert_response :not_found
    get draft_path(draft)
    assert_teams(allies: %i[axe], enemies: [])
    add_hero(draft, :lina, "ally")
    get draft_path(draft)
    assert_teams(allies: %i[axe lina], enemies: [])
  end

  test "invalid hero and side return 422 without changing saved teams and a valid choice still works" do
    sign_in(users(:one).email)
    draft = drafts(:one)
    add_hero(draft, :axe, "ally")
    [ [ -1, "ally", /не найден/ ], [ "", "ally", /не найден/ ],
      [ heroes(:lina).id, "spectator", /Сторона должна быть/ ] ].each do |hero_id, team, message|
      assert_rejected_pick(draft, hero_id, team, message)
      assert_teams(allies: %i[axe], enemies: [], status: :unprocessable_entity)
      get draft_path(draft)
      assert_teams(allies: %i[axe], enemies: [])
    end
    add_hero(draft, :lina, "ally")
    get draft_path(draft)
    assert_teams(allies: %i[axe lina], enemies: [])
  end

  test "submitted owner draft and position cannot override server choices" do
    sign_in(users(:one).email)
    post drafts_path, params: { draft: { title: "Свой драфт", user_id: users(:two).id } }
    assert_response :see_other
    draft = response.location.split("/").last
    assert_redirected_to draft_path(draft)
    follow_redirect!
    assert_select "h1", "Свой драфт"
    assert_teams(allies: [], enemies: [])

    [ [ :axe, 5 ], [ :lina, 1 ] ].each do |hero, position|
      post draft_draft_picks_path(draft), params: { draft_pick: {
        hero_id: heroes(hero).id, team: "ally", position: position, draft_id: drafts(:other).id
      } }
      assert_response :see_other
      assert_redirected_to draft_path(draft, team: "ally", anchor: "catalogue")
      follow_redirect!
      assert_select "[role=status]", "#{heroes(hero).name} добавлен. Состав сохранён."
    end
    get draft_path(draft)
    assert_teams(allies: %i[axe lina], enemies: [])
    get drafts_path
    assert_select ".draft-list-link", count: 2
    assert_select ".draft-list-link[href=?] strong", draft_path(draft), text: "Свой драфт"

    other = open_session
    sign_in(users(:two).email, client: other)
    other.get drafts_path
    other.assert_select ".draft-list-link", count: 1
    other.assert_select ".draft-list-link[href=?]", draft_path(drafts(:other))
    other.get draft_path(draft)
    other.assert_response :not_found
    other.get draft_path(drafts(:other))
    assert_teams(allies: [], enemies: [], client: other)
  end

  test "title errors preserve input and the list orders only owned drafts newest first" do
    sign_in(users(:one).email)
    [ " ", "a" * 101 ].each do |title|
      assert_no_difference("Draft.count") { post drafts_path, params: { draft: { title: title } } }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /Название/
      assert_equal title, css_select("input[name='draft[title]']").first["value"].to_s
    end
    drafts(:one).update!(created_at: 1.day.ago)
    post drafts_path, params: { draft: { title: "Новый" } }
    assert_response :see_other
    get drafts_path
    assert_select ".draft-list-link strong", text: "Новый", count: 1
    assert_equal [ "Новый", "Первый драфт" ], css_select(".draft-list-link strong").map(&:text)
  end

  test "empty catalogue has a useful message" do
    sign_in(users(:one).email)
    Hero.delete_all
    get draft_path(drafts(:one))
    assert_response :success
    assert_select "h3", "Каталог пока пуст"
    assert_select "h3", "Нет доступных рекомендаций"
  end

  private

  def sign_in(email, client: self)
    client.post session_path, params: { email: email, password: "password" }
    client.assert_redirected_to root_path
  end

  def assert_login_required(client: self)
    client.assert_redirected_to new_session_path
    client.follow_redirect!
    client.assert_response :success
    client.assert_select "h1", "Вход в аккаунт"
    client.assert_select "[role=alert]", "Сначала войдите в аккаунт"
  end

  def add_hero(draft, hero, team, catalog_team: team, client: self)
    client.post draft_draft_picks_path(draft), params: {
      draft_pick: { hero_id: heroes(hero).id, team: team }, catalog_team: catalog_team
    }
    client.assert_response :see_other
    client.assert_redirected_to draft_path(draft, team: catalog_team, anchor: "catalogue")
    client.follow_redirect!
    client.assert_response :success
    client.assert_select "[role=status]", "#{heroes(hero).name} добавлен. Состав сохранён."
  end

  def removal_path(hero, team, client: self)
    form = client.css_select("#team-#{team} form").find do |candidate|
      candidate.at_css("button")["aria-label"] == "Удалить #{heroes(hero).name}"
    end
    assert_not_nil form, "Expected a removal form for #{heroes(hero).name} in #{team}"
    form["action"]
  end

  def remove_hero(hero, team, catalog_team: team, client: self)
    client.delete removal_path(hero, team, client: client), params: { catalog_team: catalog_team }
    client.assert_response :see_other
    client.follow_redirect!
    client.assert_response :success
    client.assert_select "[role=status]", "Герой удалён. Состав сохранён."
    client.assert_select ".team-switch a[aria-current=true]", catalog_team == "enemy" ? "Противники" : "Моя команда"
  end

  def assert_rejected_pick(draft, hero_id, team, message)
    post draft_draft_picks_path(draft), params: {
      draft_pick: { hero_id: hero_id, team: team }, catalog_team: "enemy"
    }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: message
    assert_select ".team-switch a[aria-current=true]", "Противники"
  end

  def assert_teams(allies:, enemies:, status: :success, client: self)
    client.assert_response status
    client.assert_select ".team-slot", count: 10
    { "ally" => allies, "enemy" => enemies }.each do |team, expected|
      client.assert_select "#team-#{team} .team-count", "#{expected.compact.size} / 5"
      5.times do |index|
        hero = expected[index]
        slot = "#team-#{team} .team-slot:nth-child(#{index + 1})"
        client.assert_select "#{slot} .slot-number", (index + 1).to_s
        client.assert_select "#{slot} strong", hero ? heroes(hero).name : "Свободное место"
      end
    end
  end
end
