class DraftPick < ApplicationRecord
  belongs_to :draft
  belongs_to :hero

  validates :team, inclusion: { in: %w[ally enemy] }
  validates :position, numericality: { only_integer: true, in: 1..5 },
    uniqueness: { scope: [ :draft_id, :team ] }
  validates :hero_id, uniqueness: { scope: :draft_id }
end
