require "test_helper"

class DraftLiveUpdatesTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @draft = drafts(:one)
    @stream = DraftUpdatesChannel.broadcasting_for(@draft)
    post session_path, params: { email: users(:one).email, password: "password" }
    assert_redirected_to root_path
  end

  test "editor offers an authorized subscription and a frame with a permanent local search" do
    get draft_path(@draft, team: "enemy")
    assert_response :success
    assert_select "turbo-cable-stream-source[channel=DraftUpdatesChannel][data-draft-id=?]", @draft.id
    assert_select "turbo-frame#editor_draft_#{@draft.id} [data-draft-team=enemy]"
    assert_select "#search_draft_#{@draft.id}[data-turbo-permanent] #hero-search"
  end

  test "adding and deleting broadcast invalidations and return local stream feedback" do
    assert_broadcasts(@stream, 1) do
      post draft_draft_picks_path(@draft), params: { draft_pick: { hero_id: heroes(:axe).id, team: "ally" } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_select "turbo-stream[action=update][target=?]", "feedback_draft_#{@draft.id}"
    assert_select "[role=status]", "Axe добавлен. Состав сохранён."
    assert_select "turbo-stream[action=draft_changed][target=?]", "editor_draft_#{@draft.id}"
    payload = JSON.parse(broadcasts(@stream).last)
    assert_includes payload, 'action="draft_changed"'
    assert_includes payload, "editor_draft_#{@draft.id}"
    assert_empty broadcasts(@draft.to_gid_param)

    get draft_path(@draft), headers: { "Turbo-Frame" => "editor_draft_#{@draft.id}" }
    assert_response :success
    assert_select "turbo-frame#editor_draft_#{@draft.id} #team-ally strong", text: "Axe"
    delete_path = css_select("#team-ally form").first["action"]
    assert_broadcasts(@stream, 1) { delete delete_path, as: :turbo_stream }
    assert_response :success
    assert_select "[role=status]", "Герой удалён. Состав сохранён."
  end

  test "rejected choices return 422 feedback without broadcasting" do
    post draft_draft_picks_path(@draft), params: { draft_pick: { hero_id: heroes(:axe).id, team: "ally" } }
    assert_no_broadcasts(@stream) do
      post draft_draft_picks_path(@draft), params: { draft_pick: { hero_id: heroes(:axe).id, team: "enemy" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /уже выбран/
    assert_select "turbo-stream[action=draft_changed]"
  end

  test "a rolled back pick does not publish an update" do
    assert_no_broadcasts(@stream) do
      DraftPick.transaction(requires_new: true) do
        @draft.add_pick(hero_id: heroes(:axe).id, team: "ally")
        raise ActiveRecord::Rollback
      end
    end
  end

  test "other users cannot fetch or change the private frame" do
    post session_path, params: { email: users(:two).email, password: "password" }
    get draft_path(@draft), headers: { "Turbo-Frame" => "editor_draft_#{@draft.id}" }
    assert_response :not_found
    assert_no_broadcasts(@stream) do
      post draft_draft_picks_path(@draft), params: { draft_pick: { hero_id: heroes(:lina).id, team: "ally" } }, as: :turbo_stream
    end
    assert_response :not_found
  end
end
