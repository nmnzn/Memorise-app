import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.visualViewport) {
      this.fix = () => this.#fixPosition()
      window.visualViewport.addEventListener("resize", this.fix)
      window.visualViewport.addEventListener("scroll", this.fix)
    }
  }

  disconnect() {
    if (window.visualViewport) {
      window.visualViewport.removeEventListener("resize", this.fix)
      window.visualViewport.removeEventListener("scroll", this.fix)
    }
  }

  #fixPosition() {
    const vv = window.visualViewport
    const offset = window.innerHeight - vv.height - vv.offsetTop
    this.element.style.transform = `translateY(${offset}px) translateZ(0)`
  }
}
