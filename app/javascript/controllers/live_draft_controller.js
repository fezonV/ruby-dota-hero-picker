import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["frame", "source", "status"]
  static values = { url: String }

  connect() {
    this.pending = false
    this.loading = false
    this.submitting = false
    this.observer = new MutationObserver(() => this.connectionChanged())
    this.observer.observe(this.sourceTarget, { attributes: true, attributeFilter: ["connected"] })
    this.connectionChanged()
  }

  disconnect() {
    this.observer.disconnect()
  }

  connectionChanged() {
    const connected = this.sourceTarget.hasAttribute("connected")
    this.statusTarget.textContent = connected
      ? "Изменения синхронизируются между вкладками"
      : "Ожидаем подключение для синхронизации"
    if (connected) this.refresh()
  }

  refresh() {
    this.pending = true
    this.flush()
  }

  flush() {
    const frame = this.frameTarget
    if (!this.pending || this.loading || this.submitting || frame.hasAttribute("busy")) return

    this.pending = false
    this.loading = true
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("team", frame.querySelector("[data-draft-team]").dataset.draftTeam)
    if (frame.src === url.href) {
      frame.reload()
    } else {
      frame.src = url.href
    }
  }

  loaded(event) {
    if (event.target !== this.frameTarget) return
    this.loading = false
    this.flush()
  }

  submitStarted(event) {
    if (this.frameTarget.contains(event.target)) this.submitting = true
  }

  submitEnded(event) {
    if (!this.frameTarget.contains(event.target)) return
    this.submitting = false
    this.flush()
  }

  failed(event) {
    if (event.target !== this.frameTarget) return
    this.loading = false
    this.statusTarget.textContent = "Не удалось обновить состав. Переподключитесь или обновите страницу."
  }

  missing(event) {
    if (event.target !== this.frameTarget) return
    event.preventDefault()
    Turbo.visit(event.detail.response.url)
  }
}
