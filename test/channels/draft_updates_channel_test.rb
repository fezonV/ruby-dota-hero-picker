require "test_helper"

class DraftUpdatesChannelTest < ActionCable::Channel::TestCase
  test "owner subscribes to a private draft stream and can unsubscribe" do
    stub_connection current_user: users(:one)
    subscribe draft_id: drafts(:one).id, signed_stream_name: signed_name(drafts(:one))

    assert subscription.confirmed?
    assert_has_stream_for drafts(:one)
    assert_has_no_stream drafts(:one).to_gid_param
    unsubscribe
    assert_no_streams
  end

  test "another user cannot reuse a valid signed stream name of a foreign draft" do
    stub_connection current_user: users(:two)
    subscribe draft_id: drafts(:one).id, signed_stream_name: signed_name(drafts(:one))

    assert subscription.rejected?
    assert_no_streams
  end

  test "a signed name of another draft cannot be paired with an owned draft id" do
    stub_connection current_user: users(:one)
    subscribe draft_id: drafts(:one).id, signed_stream_name: signed_name(drafts(:other))

    assert subscription.rejected?
    assert_no_streams
  end

  test "tampered names and missing drafts are rejected" do
    stub_connection current_user: users(:one)
    subscribe draft_id: drafts(:one).id, signed_stream_name: "tampered"
    assert subscription.rejected?
    assert_no_streams
    subscribe draft_id: -1, signed_stream_name: signed_name(drafts(:one))
    assert subscription.rejected?
    assert_no_streams
  end

  private

  def signed_name(draft)
    Turbo::StreamsChannel.signed_stream_name(draft)
  end
end
