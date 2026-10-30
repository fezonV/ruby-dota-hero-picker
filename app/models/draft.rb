class Draft < ApplicationRecord
  belongs_to :user
  has_many :draft_picks, dependent: :destroy
  has_many :heroes, through: :draft_picks

  normalizes :title, with: ->(title) { title.strip }
  validates :title, presence: true, length: { maximum: 100 }

  # Lock the draft so two requests cannot take the same free position.
  def add_pick(attributes)
    with_lock do
      pick = draft_picks.build(attributes)
      occupied = draft_picks.where(team: pick.team).pluck(:position)
      pick.position = ((1..5).to_a - occupied).first

      if pick.position.nil?
        pick.errors.add(:base, "В этой команде уже пять героев. Сначала удалите одного.")
      else
        pick.save
      end
      pick
    end
  end

  # Educational feature ratings, not match statistics or win probabilities.
  # Missing allied features receive priority; enemy durability adds value to damage.
  def recommendations(limit: 5)
    picks = draft_picks.includes(:hero).to_a
    allies = picks.select { |pick| pick.team == "ally" }.map(&:hero)
    return [] if allies.size >= 5

    enemies = picks.select { |pick| pick.team == "enemy" }.map(&:hero)
    needs = {
      "support" => [ 3 - allies.sum(&:support), 0 ].max,
      "control" => [ 4 - allies.sum(&:control), 0 ].max,
      "damage" => [ 5 - allies.sum(&:damage), 0 ].max,
      "durability" => [ 3 - allies.sum(&:durability), 0 ].max
    }
    explanations = {
      "support" => "Команде нужна поддержка",
      "control" => "Команде нужен контроль",
      "damage" => "Команде нужен урон",
      "durability" => "Команде нужен герой, принимающий урон"
    }

    Hero.where.not(id: picks.map(&:hero_id)).map do |hero|
      score = 0
      reasons = []
      needs.each do |feature, deficit|
        contribution = [ hero.public_send(feature), deficit ].min * 2
        next if contribution.zero?

        score += contribution
        reasons << explanations.fetch(feature)
      end
      if enemies.sum(&:durability) >= 4 && hero.damage.positive?
        score += hero.damage
        reasons << "У противника плотный состав: полезен дополнительный урон"
      end
      reasons << "Базовый вариант: основные потребности команды закрыты" if reasons.empty?
      { hero: hero, score: score, reasons: reasons }
    end.sort_by { |item| [ -item[:score], item[:hero].name.downcase, item[:hero].id ] }.first(limit)
  end
end
