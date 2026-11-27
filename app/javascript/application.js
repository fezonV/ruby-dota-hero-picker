// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.draft_changed = function () {
  this.targetElements.forEach((frame) => {
    frame.dispatchEvent(new CustomEvent("draft:changed", { bubbles: true }))
  })
}
