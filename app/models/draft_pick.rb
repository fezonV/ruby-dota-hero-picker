class DraftPick < ApplicationRecord
  belongs_to :draft
  belongs_to :hero

  after_commit :broadcast_draft_change, on: %i[create destroy]

  validates :team, inclusion: { in: %w[ally enemy] }
  validates :position, numericality: { only_integer: true, in: 1..5 },
    uniqueness: { scope: [ :draft_id, :team ] }
  validates :hero_id, uniqueness: { scope: :draft_id }

  private

  def broadcast_draft_change
    Turbo::StreamsChannel.broadcast_action_to DraftUpdatesChannel.broadcasting_for(draft), action: :draft_changed,
      target: ActionView::RecordIdentifier.dom_id(draft, :editor), content: ""
  end
end
