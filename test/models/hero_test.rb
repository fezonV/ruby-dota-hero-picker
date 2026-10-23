require "test_helper"

class HeroTest < ActiveSupport::TestCase
  test "normalizes name and requires a unique name regardless of case" do
    hero = Hero.new(name: "  crystal maiden  ", role: "Support")
    assert_equal "crystal maiden", hero.name
    assert_not hero.valid?
    assert hero.errors.of_kind?(:name, :taken)
  end

  test "requires name role and integer feature ratings between zero and three" do
    hero = Hero.new(name: " ", role: " ", support: 4, control: -1, damage: 1.5)
    assert_not hero.valid?
    %i[name role support control damage].each { |field| assert hero.errors[field].any? }
  end

  test "database rejects invalid feature ratings without model validation" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Hero.transaction(requires_new: true) { heroes(:axe).update_columns(support: 4) }
    end
  end

  test "cannot remove a hero used in a draft" do
    hero = heroes(:axe)
    drafts(:one).draft_picks.create!(hero: hero, team: "ally", position: 1)
    assert_not hero.destroy
    assert Hero.exists?(hero.id)
  end
end
