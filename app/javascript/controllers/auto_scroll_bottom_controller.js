import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()

    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    const container = this.element.closest(".chat-messages") || this.element
    requestAnimationFrame(() => {
      container.scrollTop = container.scrollHeight
    })
  }
}
