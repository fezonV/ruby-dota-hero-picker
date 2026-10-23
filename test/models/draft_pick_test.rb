require "test_helper"

class DraftPickTest < ActiveSupport::TestCase
  setup do
    @draft = drafts(:one)
    @draft.draft_picks.create!(hero: heroes(:axe), team: "ally", position: 1)
  end

  test "cannot repeat a hero even on the other team" do
    pick = @draft.draft_picks.build(hero: heroes(:axe), team: "enemy", position: 1)
    assert_not pick.valid?
    assert pick.errors.of_kind?(:hero_id, :taken)
  end

  test "cannot occupy a taken position but may use the same number on the opposing team" do
    pick = @draft.draft_picks.build(hero: heroes(:maiden), team: "ally", position: 1)
    assert_not pick.valid?
    assert pick.errors.of_kind?(:position, :taken)
    pick.team = "enemy"
    assert pick.valid?
  end

  test "requires an existing draft hero valid team and a position from one to five" do
    pick = DraftPick.new(team: "spectator", position: 6)
    assert_not pick.valid?
    %i[draft hero team position].each { |field| assert pick.errors[field].any? }
  end

  test "database rejects duplicate heroes and occupied positions" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      DraftPick.transaction(requires_new: true) do
        @draft.draft_picks.build(hero: heroes(:axe), team: "enemy", position: 2).save!(validate: false)
      end
    end
    assert_raises(ActiveRecord::RecordNotUnique) do
      DraftPick.transaction(requires_new: true) do
        @draft.draft_picks.build(hero: heroes(:maiden), team: "ally", position: 1).save!(validate: false)
      end
    end
  end

  test "database rejects sixth position and invalid team" do
    [ [ "ally", 6 ], [ "spectator", 2 ] ].each do |team, position|
      assert_raises(ActiveRecord::StatementInvalid) do
        DraftPick.transaction(requires_new: true) do
          @draft.draft_picks.build(hero: heroes(:maiden), team: team, position: position).save!(validate: false)
        end
      end
    end
  end
end
