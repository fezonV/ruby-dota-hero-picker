require "test_helper"

class DraftLockingTest < ActiveSupport::TestCase
  # Separate connections must see committed data to test real PostgreSQL locks.
  self.use_transactional_tests = false

  setup do
    @draft = users(:one).drafts.create!(title: "Параллельный выбор")
  end

  teardown do
    @draft.destroy!
  end

  test "simultaneous additions occupy different free positions" do
    picks = add_together(:axe, :maiden)
    assert picks.all?(&:persisted?)
    assert_equal [ 1, 2 ], @draft.draft_picks.order(:position).pluck(:position)
  end

  test "only one simultaneous request takes the last position" do
    %i[juggernaut lina sven lion].each do |hero|
      @draft.add_pick(hero_id: heroes(hero).id, team: "ally")
    end
    picks = add_together(:axe, :maiden)
    assert_equal 1, picks.count(&:persisted?)
    assert_match(/уже пять героев/, picks.find(&:new_record?).errors.full_messages.join)
    assert_equal [ 1, 2, 3, 4, 5 ], @draft.draft_picks.order(:position).pluck(:position)
  end

  test "simultaneous duplicate requests save a hero only once" do
    picks = add_together(:axe, :axe)
    assert_equal 1, picks.count(&:persisted?)
    assert_equal 1, @draft.draft_picks.count
    assert picks.find(&:new_record?).errors.of_kind?(:hero_id, :taken)
  end

  private

  def add_together(*hero_names)
    ready = Queue.new
    start = Queue.new
    # Read fixture IDs before starting threads; each thread gets its own connection.
    hero_ids = hero_names.map { |name| heroes(name).id }
    threads = hero_ids.map do |hero_id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          draft = Draft.find(@draft.id)
          ready << true
          start.pop
          draft.add_pick(hero_id: hero_id, team: "ally")
        end
      end
    end
    threads.size.times { ready.pop }
    threads.size.times { start << true }
    threads.map(&:value)
  end
end
