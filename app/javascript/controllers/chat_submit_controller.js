import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "icon", "spinner"]

  loading() {
    this.buttonTarget.disabled = true
    this.iconTarget.classList.add("d-none")
    this.spinnerTarget.classList.remove("d-none")
  }

  preventBlur(event) {
    event.preventDefault()
  }
}
