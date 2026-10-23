class Draft < ApplicationRecord
  belongs_to :user
  has_many :draft_picks, dependent: :destroy
  has_many :heroes, through: :draft_picks

  normalizes :title, with: ->(title) { title.strip }
  validates :title, presence: true, length: { maximum: 100 }

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
