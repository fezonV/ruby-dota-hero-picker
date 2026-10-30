# Портреты героев Dota 2

Официальные портреты Valve со [страницы героев Dota 2](https://www.dota2.com/heroes).
Загружены 30 октября 2026 года с CDN Steam. PNG сохранены без изменений;
размер каждого — 256×144 px, соотношение сторон — 16:9.

| Герой | Исходник |
| --- | --- |
| Axe | [axe.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/axe.png) |
| Centaur Warrunner | [centaur.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/centaur.png) |
| Crystal Maiden | [crystal_maiden.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/crystal_maiden.png) |
| Dazzle | [dazzle.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/dazzle.png) |
| Juggernaut | [juggernaut.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/juggernaut.png) |
| Lina | [lina.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/lina.png) |
| Lion | [lion.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/lion.png) |
| Phantom Assassin | [phantom_assassin.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/phantom_assassin.png) |
| Sniper | [sniper.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/sniper.png) |
| Sven | [sven.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/sven.png) |
| Tidehunter | [tidehunter.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/tidehunter.png) |
| Windranger | [windrunner.png](https://cdn.akamai.steamstatic.com/apps/dota2/images/dota_react/heroes/windrunner.png) |

Максимальный размер в интерфейсе — 80×45 CSS px: исходники покрывают плотность
до 3× без увеличения. На телефоне и в слотах — 64×36 CSS px. Общий partial
`shared/ui/hero_portrait` сохраняет пропорции и показывает весь портрет.
Имена связываются с файлами в `app/helpers/heroes_helper.rb`; при расширении
учебного каталога нужно добавить исходник и запись в сопоставление.
