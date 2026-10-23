# Small educational catalogue. Ratings are manually assigned examples (0..3),
# not live Dota statistics, win rates, or patch-specific balance claims.
[
  [ "Crystal Maiden", "Поддержка", 3, 3, 1, 0 ],
  [ "Axe", "Инициация", 0, 2, 1, 3 ],
  [ "Juggernaut", "Основной урон", 0, 0, 3, 1 ],
  [ "Lina", "Урон и контроль", 0, 2, 3, 0 ],
  [ "Lion", "Поддержка", 3, 3, 1, 0 ],
  [ "Dazzle", "Поддержка", 3, 0, 1, 1 ],
  [ "Tidehunter", "Инициация", 0, 3, 1, 3 ],
  [ "Centaur Warrunner", "Инициация", 0, 2, 1, 3 ],
  [ "Phantom Assassin", "Основной урон", 0, 0, 3, 0 ],
  [ "Sniper", "Основной урон", 0, 1, 3, 0 ],
  [ "Sven", "Основной урон", 0, 2, 3, 2 ],
  [ "Windranger", "Урон и контроль", 1, 2, 2, 1 ]
].each do |name, role, support, control, damage, durability|
  Hero.find_or_initialize_by(name: name).update!(
    role: role, support: support, control: control, damage: damage, durability: durability
  )
end
