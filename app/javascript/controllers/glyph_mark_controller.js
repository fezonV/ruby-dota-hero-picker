import { Controller } from "@hotwired/stimulus"
import { createAegisAscii } from "aegis-ascii"

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.animation = createAegisAscii(this.canvasTarget, { pointerSurface: document.documentElement })
  }

  disconnect() {
    this.animation?.destroy()
  }

  beforeCache() {
    this.element.querySelectorAll("input[data-sensitive-password]").forEach((field) => {
      field.value = ""
      field.type = "password"
    })
    this.element.querySelectorAll("button[data-password-id]").forEach((button) => {
      button.setAttribute("aria-pressed", "false")
      button.setAttribute("aria-label", `Показать ${button.dataset.passwordLabel}`)
    })
    this.animation?.destroy()
  }

  togglePassword(event) {
    const button = event.currentTarget
    const field = document.getElementById(button.dataset.passwordId)
    const show = field.type === "password"
    field.type = show ? "text" : "password"
    button.setAttribute("aria-pressed", String(show))
    button.setAttribute("aria-label", `${show ? "Скрыть" : "Показать"} ${button.dataset.passwordLabel}`)
  }
}
