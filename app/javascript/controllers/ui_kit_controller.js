import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hero", "search", "noResults", "selection"]

  filter() {
    const query = this.searchTarget.value.trim().toLocaleLowerCase("ru")
    this.heroTargets.forEach((hero) => {
      hero.hidden = !`${hero.dataset.name} ${hero.dataset.role}`.toLocaleLowerCase("ru").includes(query)
    })
    this.noResultsTarget.hidden = this.heroTargets.some((hero) => !hero.hidden)
  }

  select(event) {
    this.choose(event.currentTarget)
  }

  recommend() {
    this.searchTarget.value = ""
    this.filter()
    this.choose(this.heroTargets[0])
  }

  choose(selected) {
    this.heroTargets.forEach((hero) => {
      const active = hero === selected
      hero.setAttribute("aria-pressed", String(active))
      hero.querySelector(".hero-choice").textContent = active ? "Выбран" : "Выбрать"
    })
    this.selectionTarget.textContent = `Выбран ${selected.dataset.name}. Это демонстрация, выбор не сохраняется.`
  }
}
