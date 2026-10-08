import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.glyphs = []
    this.pointer = { x: 60, y: 60, active: false }
    this.motionEnabled = !window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.frame = 0
    this.drawMark()
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    clearTimeout(this.burstTimeout)
  }

  drawMark() {
    const paths = [
      { points: [[60, 12], [96, 27], [91, 65], [78, 90], [60, 107], [42, 90], [29, 65], [24, 27], [60, 12]], color: "#9781d0" },
      { points: [[60, 34], [45, 48], [60, 82], [75, 48], [60, 34]], color: "#28685e" },
      { points: [[45, 48], [75, 48]], color: "#28685e" }
    ]

    paths.forEach(({ points, color }) => {
      for (let i = 1; i < points.length; i += 1) {
        const [x1, y1] = points[i - 1]
        const [x2, y2] = points[i]
        const length = Math.hypot(x2 - x1, y2 - y1)
        const count = Math.max(1, Math.round(length / 6.5))

        for (let j = 0; j < count; j += 1) {
          const t = (j + 0.5) / count
          const x = x1 + (x2 - x1) * t
          const y = y1 + (y2 - y1) * t
          const glyph = document.createElementNS("http://www.w3.org/2000/svg", "text")
          glyph.textContent = j % 4 === 3 ? "·" : "—"
          glyph.setAttribute("text-anchor", "middle")
          glyph.setAttribute("dominant-baseline", "central")
          glyph.setAttribute("font-family", "Consolas, monospace")
          glyph.setAttribute("font-size", "10")
          glyph.setAttribute("font-weight", "700")
          glyph.setAttribute("fill", color)
          this.canvasTarget.append(glyph)
          this.glyphs.push({ element: glyph, x, y, angle: Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI, dx: 0, dy: 0, rotation: 0, vx: 0, vy: 0, vr: 0 })
        }
      }
    })
  }

  move(event) {
    if (!this.motionEnabled || event.pointerType === "touch") return
    const bounds = this.canvasTarget.getBoundingClientRect()
    this.pointer.x = (event.clientX - bounds.left) / bounds.width * 120
    this.pointer.y = (event.clientY - bounds.top) / bounds.height * 120
    this.pointer.active = true
    this.animate()
  }

  leave() {
    this.pointer.active = false
    this.animate()
  }

  burst() {
    if (!this.motionEnabled) return
    this.pointer = { x: 60, y: 58, active: true }
    this.animate()
    clearTimeout(this.burstTimeout)
    this.burstTimeout = setTimeout(() => {
      this.pointer.active = false
      this.animate()
    }, 450)
  }

  animate() {
    if (!this.frame) this.frame = requestAnimationFrame(() => this.renderFrame())
  }

  renderFrame() {
    let energy = 0
    this.glyphs.forEach((glyph) => {
      const dx = glyph.x - this.pointer.x
      const dy = glyph.y - this.pointer.y
      const distance = Math.hypot(dx, dy)
      const power = this.motionEnabled && this.pointer.active ? Math.max(0, 1 - distance / 48) : 0
      const targetX = distance ? dx / distance * power * 8 : 0
      const targetY = distance ? dy / distance * power * 8 : 0
      const targetRotation = power * (dx > 0 ? 1 : -1) * 20
      glyph.vx = (glyph.vx + (targetX - glyph.dx) * 0.14) * 0.68
      glyph.vy = (glyph.vy + (targetY - glyph.dy) * 0.14) * 0.68
      glyph.vr = (glyph.vr + (targetRotation - glyph.rotation) * 0.13) * 0.7
      glyph.dx += glyph.vx
      glyph.dy += glyph.vy
      glyph.rotation += glyph.vr
      glyph.element.setAttribute("transform", `translate(${glyph.x + glyph.dx} ${glyph.y + glyph.dy}) rotate(${glyph.angle + glyph.rotation})`)
      energy += Math.abs(glyph.vx) + Math.abs(glyph.vy) + Math.abs(glyph.vr)
    })
    this.frame = 0
    if (energy > 0.04 || this.pointer.active) this.frame = requestAnimationFrame(() => this.renderFrame())
  }
}
