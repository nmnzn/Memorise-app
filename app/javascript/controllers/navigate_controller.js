import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  go(event) {
    if (!event.target.closest("form")) {
      window.location = this.urlValue
    }
  }
}
