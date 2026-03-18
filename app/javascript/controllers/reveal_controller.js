import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]
  static values  = { nextUrl: String }

  connect() {
    setTimeout(() => {
      window.location.href = this.nextUrlValue
    }, 1500)
  }
}
