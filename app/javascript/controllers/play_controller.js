import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answer", "actions", "knewBtn", "nopeBtn", "revealBtn"]
  static values  = { correct: String }

  // Flip card — inchangé
  toggleAnswer() {
    this.revealBtnTarget.classList.add("hidden")
    this.answerTarget.classList.remove("hidden")
    this.actionsTarget.classList.remove("hidden")
  }

  // QCM
  selectChoice(event) {
    const chosen    = event.currentTarget.dataset.choice
    const isCorrect = chosen === this.correctValue

    // Feedback couleur sur le bouton cliqué
    event.currentTarget.classList.add(isCorrect ? "qcm-correct" : "qcm-wrong")

    // Désactive tous les boutons pour éviter double clic
    this.element.querySelectorAll(".play-qcm-btn").forEach(btn => btn.disabled = true)

    // Auto-submit après 800ms
    setTimeout(() => {
      const form = isCorrect ? this.knewBtnTarget.closest("form") : this.nopeBtnTarget.closest("form")
      form.requestSubmit()
    }, 800)
  }
}
