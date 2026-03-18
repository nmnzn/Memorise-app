import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]
  static values  = { nextUrl: String }

  connect() {
    requestAnimationFrame(() => {
      this.barTarget.style.transition = "width 1500ms linear"
      this.barTarget.style.width = "100%"
    })

    setTimeout(() => {
      window.location.href = this.nextUrlValue
    }, 1500)
  }
}
