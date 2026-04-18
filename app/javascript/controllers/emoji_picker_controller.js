import { Controller } from "@hotwired/stimulus"
import { Picker } from "emoji-picker-element"

export default class extends Controller {
  static targets = ["input", "trigger", "pickerContainer"]

  connect() {
    // Create the picker
    this.picker = new Picker({
      emojiVersion: "15",
      previewPosition: "none",
      dynamicWidth: true
    })

    // Add to our hidden container
    this.pickerContainerTarget.appendChild(this.picker)

    // Listen for emoji selection
    this.picker.addEventListener("emoji-click", (event) => {
      // Update input and trigger with the selected emoji
      this.inputTarget.value = event.detail.unicode
      this.triggerTarget.textContent = event.detail.unicode
      // Close picker
      this.pickerContainerTarget.classList.remove("open")
    })

    // Set initial trigger text from input value
    const initialValue = this.inputTarget.value
    if (initialValue) {
      this.triggerTarget.textContent = initialValue
    }
  }

  toggle(event) {
    event.preventDefault()
    this.pickerContainerTarget.classList.toggle("open")
  }

  close() {
    this.pickerContainerTarget.classList.remove("open")
  }
}