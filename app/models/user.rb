class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^\s@]+@[^\s@]+\z/

  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: EMAIL_FORMAT }
  validates :password_confirmation, presence: true, if: -> { password.present? }
end
