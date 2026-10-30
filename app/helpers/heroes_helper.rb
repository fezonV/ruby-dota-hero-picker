module HeroesHelper
  HERO_PORTRAITS = {
    "Crystal Maiden" => "crystal_maiden",
    "Axe" => "axe",
    "Juggernaut" => "juggernaut",
    "Lina" => "lina",
    "Lion" => "lion",
    "Dazzle" => "dazzle",
    "Tidehunter" => "tidehunter",
    "Centaur Warrunner" => "centaur",
    "Phantom Assassin" => "phantom_assassin",
    "Sniper" => "sniper",
    "Sven" => "sven",
    "Windranger" => "windrunner"
  }.freeze

  def hero_portrait_path(name)
    slug = HERO_PORTRAITS[name]
    "/heroes/#{slug}.png" if slug
  end
end
