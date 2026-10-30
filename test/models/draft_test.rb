require "test_helper"

class DraftTest < ActiveSupport::TestCase
  test "requires an owner and a nonblank title of at most one hundred characters" do
    draft = Draft.new(title: " ")
    assert_not draft.valid?
    assert draft.errors[:user].any?
    assert draft.errors[:title].any?
    draft.title = "a" * 101
    assert_not draft.valid?
  end

  test "user owns drafts and another user cannot find them through their association" do
    other = User.create!(email: "other@example.test", password: "password", password_confirmation: "password")
    assert_equal drafts(:one), users(:one).drafts.find(drafts(:one).id)
    assert_raises(ActiveRecord::RecordNotFound) { other.drafts.find(drafts(:one).id) }
  end

  test "recommendations change with allied needs and explain the score" do
    draft = drafts(:one)
    before = draft.recommendations.find { |item| item[:hero] == heroes(:maiden) }
    draft.draft_picks.create!(hero: heroes(:juggernaut), team: "ally", position: 1)
    draft.draft_picks.create!(hero: heroes(:axe), team: "ally", position: 2)
    after = draft.recommendations.find { |item| item[:hero] == heroes(:maiden) }
    assert_operator before[:score], :>, after[:score]
    assert_includes after[:reasons], "Команде нужна поддержка"
    assert_equal heroes(:maiden), draft.recommendations.first[:hero]
  end

  test "excludes all selected heroes and uses enemy composition" do
    draft = drafts(:one)
    initial = draft.recommendations(limit: Hero.count).find { |item| item[:hero] == heroes(:lina) }[:score]
    draft.draft_picks.create!(hero: heroes(:axe), team: "enemy", position: 1)
    draft.draft_picks.create!(hero: heroes(:juggernaut), team: "enemy", position: 2)
    results = draft.recommendations(limit: Hero.count)
    assert_not_includes results.map { |item| item[:hero] }, heroes(:axe)
    assert_not_includes results.map { |item| item[:hero] }, heroes(:juggernaut)
    lina = results.find { |item| item[:hero] == heroes(:lina) }
    assert_equal initial + heroes(:lina).damage, lina[:score]
    assert lina[:reasons].any? { |reason| reason.include?("противника") }
  end

  test "full allied team has no recommendations" do
    draft = drafts(:one)
    5.times do |index|
      hero = Hero.create!(name: "Test hero #{index}", role: "Test")
      draft.draft_picks.create!(hero: hero, team: "ally", position: index + 1)
    end
    assert_empty draft.recommendations
  end

  test "deleting draft removes picks but preserves catalogue" do
    draft = drafts(:one)
    draft.draft_picks.create!(hero: heroes(:axe), team: "ally", position: 1)
    assert_difference("DraftPick.count", -1) { draft.destroy! }
    assert Hero.exists?(heroes(:axe).id)
  end
end
