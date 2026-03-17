import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answer", "actions"]

  toggleAnswer() {
    this.answerTarget.classList.remove("hidden")
    this.actionsTarget.classList.remove("hidden")
  }
}
