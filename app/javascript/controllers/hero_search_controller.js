import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hero", "search", "noResults"]

  connect() {
    this.filter()
  }

  filter() {
    const query = this.searchTarget.value.trim().toLocaleLowerCase("ru")
    this.heroTargets.forEach((hero) => {
      hero.hidden = !`${hero.dataset.name} ${hero.dataset.role}`.toLocaleLowerCase("ru").includes(query)
    })
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.hidden = this.heroTargets.some((hero) => !hero.hidden)
    }
  }
}
