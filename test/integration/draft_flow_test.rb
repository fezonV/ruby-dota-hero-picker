require "test_helper"

class DraftFlowTest < ActionDispatch::IntegrationTest
  test "register, sign in separately, build both teams and reopen the saved draft after signing in again" do
    get new_registration_path
    assert_response :success
    assert_difference("User.count", 1) do
      post registration_path, params: { user: {
        email: "draft-journey@example.test", password: "password", password_confirmation: "password"
      } }
    end
    assert_redirected_to registration_created_path
    get drafts_path
    assert_redirected_to new_session_path

    user = User.find_by!(email: "draft-journey@example.test")
    sign_in(user)
    get root_path
    assert_select "a[href=?]", drafts_path, text: "Мои драфты"
    get drafts_path
    assert_select "h2", "Пока нет драфтов"
    assert_select "a[href=?]", new_draft_path
    get new_draft_path
    assert_select "label[for=draft_title]", "Название драфта"

    assert_difference("Draft.count", 1) do
      post drafts_path, params: { draft: { title: "  Состав для защиты  ", user_id: users(:two).id } }
    end
    draft = user.drafts.find_by!(title: "Состав для защиты")
    assert_equal user, draft.user
    assert_response :see_other
    assert_redirected_to draft_path(draft)
    follow_redirect!
    assert_select "h1", draft.title
    assert_select ".team-slot", count: 10

    add_hero(draft, :juggernaut, "ally")
    add_hero(draft, :axe, "ally")
    %i[centaur tidehunter sniper phantom dazzle].each { |hero| add_hero(draft, hero, "enemy") }

    recommendation = draft.recommendations.first
    assert_equal heroes(:maiden), recommendation[:hero]
    assert_equal 13, recommendation[:score]
    assert_includes recommendation[:reasons], "Команде нужна поддержка"
    assert_select "#recommendations", text: /Учебная эвристика.*не вероятность победы/m
    assert_select ".recommendation[data-hero-id=?]", recommendation[:hero].id do
      assert_select "h3", "Crystal Maiden"
      assert_select ".recommendation-heading span", "13 балл."
      recommendation[:reasons].each { |reason| assert_select "li", reason }
      assert_select "form input[name='draft_pick[team]'][value=ally]"
    end
    assert_select "#catalogue button[aria-label='Добавить Axe'][disabled]"

    # Even when the catalogue targets enemies, recommendations always add an ally.
    add_hero(draft, :maiden, "ally", catalog_team: "enemy")
    assert_select ".team-switch a[aria-current=true]", "Противники"
    assert_equal "ally", draft.draft_picks.find_by!(hero: heroes(:maiden)).team
    add_hero(draft, :lina, "ally")
    add_hero(draft, :sven, "ally")
    assert_select "#recommendations h3", "Команда собрана"
    assert_select ".recommendation", count: 0
    assert_equal 10, draft.draft_picks.count

    expected = draft.draft_picks.order(:team, :position).pluck(:hero_id, :team, :position)
    assert_equal %i[juggernaut axe maiden lina sven].map { |name| heroes(name).id },
      draft.draft_picks.where(team: "ally").order(:position).pluck(:hero_id)
    assert_equal %i[centaur tidehunter sniper phantom dazzle].map { |name| heroes(name).id },
      draft.draft_picks.where(team: "enemy").order(:position).pluck(:hero_id)
    %w[ally enemy].each do |team|
      assert_equal [ 1, 2, 3, 4, 5 ], draft.draft_picks.where(team: team).order(:position).pluck(:position)
    end
    get drafts_path
    assert_select ".draft-list-link", count: 1
    assert_select ".draft-list-link", text: /Моя команда: 5 \/ 5 · Противники: 5 \/ 5/
    get draft_path(draft)
    assert_saved_teams(draft)
    delete session_path
    get draft_path(draft)
    assert_redirected_to new_session_path
    sign_in(user)
    get draft_path(draft)
    assert_saved_teams(draft)
    assert_equal expected, draft.draft_picks.order(:team, :position).pluck(:hero_id, :team, :position)
  end

  test "guests cannot list create open or change drafts" do
    draft = drafts(:one)
    pick = draft.draft_picks.create!(hero: heroes(:axe), team: "ally", position: 1)
    before = pick.attributes
    assert_no_difference([ "Draft.count", "DraftPick.count" ]) do
      [ drafts_path, new_draft_path, draft_path(draft) ].each do |path|
        get path
        assert_redirected_to new_session_path
      end
      post drafts_path, params: { draft: { title: "Гостевой" } }
      assert_redirected_to new_session_path
      post draft_draft_picks_path(draft), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
      assert_redirected_to new_session_path
      delete draft_draft_pick_path(draft, pick)
      assert_redirected_to new_session_path
    end
    assert_equal before, pick.reload.attributes
  end

  test "another user cannot read add or delete someone else's picks and missing resources return 404" do
    draft = drafts(:one)
    pick = draft.draft_picks.create!(hero: heroes(:axe), team: "ally", position: 1)
    sign_in(users(:two))
    before = pick.attributes
    assert_no_difference([ "Draft.count", "DraftPick.count" ]) do
      get draft_path(draft)
      assert_response :not_found
      post draft_draft_picks_path(draft), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
      assert_response :not_found
      delete draft_draft_pick_path(draft, pick)
      assert_response :not_found
      delete draft_draft_pick_path(drafts(:other), pick)
      assert_response :not_found
      get draft_path(-1)
      assert_response :not_found
      post draft_draft_picks_path(-1), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }
      assert_response :not_found
      delete draft_draft_pick_path(drafts(:other), -1)
      assert_response :not_found
    end
    assert_equal before, pick.reload.attributes
    get drafts_path
    assert_select ".draft-list-link", count: 1
    assert_select ".draft-list-link strong", "Чужой драфт"
  end

  test "duplicate full team invalid side and invalid hero return 422 and valid actions still work" do
    sign_in(users(:one))
    draft = drafts(:one)
    add_hero(draft, :axe, "ally")
    assert_rejected_pick(draft, heroes(:axe).id, "enemy", /уже выбран/)
    assert_select ".team-switch a[aria-current=true]", "Противники"
    assert_rejected_pick(draft, -1, "ally", /не найден/)
    assert_rejected_pick(draft, "", "ally", /не найден/)
    assert_rejected_pick(draft, heroes(:lina).id, "spectator", /Сторона должна быть/)
    %i[juggernaut maiden lina sven].each { |hero| add_hero(draft, hero, "ally") }
    before = draft.draft_picks.order(:id).map(&:attributes)
    assert_rejected_pick(draft, heroes(:lion).id, "ally", /уже пять героев/)
    assert_equal before, draft.draft_picks.order(:id).map(&:attributes)
    add_hero(draft, :lion, "enemy")
    assert_equal [ 1, 2, 3, 4, 5 ], draft.draft_picks.where(team: "ally").order(:position).pluck(:position)
  end

  test "deletion frees the same position and returns recommendations" do
    sign_in(users(:one))
    draft = drafts(:one)
    %i[axe juggernaut maiden lina sven].each { |hero| add_hero(draft, hero, "ally") }
    pick = draft.draft_picks.find_by!(hero: heroes(:maiden))
    assert_difference("DraftPick.count", -1) do
      delete draft_draft_pick_path(draft, pick), params: { catalog_team: "enemy" }
    end
    assert_response :see_other
    assert_redirected_to draft_path(draft, team: "enemy")
    follow_redirect!
    assert_select "[role=status]", text: /Герой удалён. Состав сохранён./
    assert_select ".recommendation", minimum: 1
    assert_select "#team-ally .team-slot:nth-child(3)", text: /Свободное место/
    assert_select "#catalogue button[aria-label='Добавить Crystal Maiden']:not([disabled])"
    add_hero(draft, :lion, "ally")
    assert_equal 3, draft.draft_picks.find_by!(hero: heroes(:lion)).position
    assert_select "#recommendations h3", "Команда собрана"
  end

  test "title errors preserve input and the list orders only owned drafts newest first" do
    sign_in(users(:one))
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
    sign_in(users(:one))
    Hero.delete_all
    get draft_path(drafts(:one))
    assert_response :success
    assert_select "h3", "Каталог пока пуст"
    assert_select "h3", "Нет доступных рекомендаций"
  end

  private

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
    assert_redirected_to root_path
  end

  def add_hero(draft, hero, team, catalog_team: team)
    assert_difference("DraftPick.count", 1) do
      post draft_draft_picks_path(draft), params: {
        draft_pick: { hero_id: heroes(hero).id, team: team, position: 5, draft_id: drafts(:other).id },
        catalog_team: catalog_team
      }
    end
    assert_response :see_other
    assert_redirected_to draft_path(draft, team: catalog_team, anchor: "catalogue")
    follow_redirect!
    assert_response :success
    assert_select "[role=status]", text: /Состав сохранён/
  end

  def assert_rejected_pick(draft, hero_id, team, message)
    assert_no_difference("DraftPick.count") do
      post draft_draft_picks_path(draft), params: {
        draft_pick: { hero_id: hero_id, team: team }, catalog_team: "enemy"
      }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: message
  end

  def assert_saved_teams(draft)
    assert_response :success
    assert_select "h1", draft.title
    draft.draft_picks.includes(:hero).each do |pick|
      assert_select "#team-#{pick.team} .team-slot:nth-child(#{pick.position}) strong", pick.hero.name
    end
  end
end
