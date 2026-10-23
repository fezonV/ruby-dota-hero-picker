class Hero < ApplicationRecord
  FEATURES = %w[support control damage durability].freeze

  has_many :draft_picks, dependent: :restrict_with_error
  normalizes :name, :role, with: ->(value) { value.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true
  validates(*FEATURES, numericality: { only_integer: true, in: 0..3 })
end
