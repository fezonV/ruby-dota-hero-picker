require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and password" do
    user = User.new(email: "new-player@example.com", password: "password")

    assert user.valid?
  end

  test "requires an email" do
    user = User.new(password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires a valid email" do
    user = User.new(email: "invalid-email", password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "normalizes email" do
    user = User.create!(email: "  NEW-PLAYER@Example.COM ", password: "password")

    assert_equal "new-player@example.com", user.email
  end

  test "requires a unique email" do
    user = User.new(email: users(:one).email.upcase, password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "authenticates with the correct password" do
    user = User.create!(email: "secure@example.com", password: "secret")

    assert user.authenticate("secret")
    assert_not user.authenticate("incorrect")
  end
end
