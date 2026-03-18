import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body", "chevron"]

  toggle() {
    this.bodyTarget.classList.toggle("hidden")
    this.chevronTarget.classList.toggle("rotated")
  }
}
