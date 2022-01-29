export default {
  mounted() {
    this.guess = "";
    this.el.addEventListener("app:keyClicked", (event) => {
      this.onKeyClicked(event.detail.key);
    });
    this.handleEvent("app:resetGuess", () => {
      this.guess = "";
      this.refreshInputElement();
    });
  },

  updated() {
    this.refreshInputElement();
  },

  onKeyClicked(key) {
    if (key === "Enter") {
      this.onEnter();
    } else if (key === "Backspace") {
      this.onBackspace();
    } else {
      this.onChar(key);
    }
  },

  onEnter() {
    this.pushEvent("submit", { guess: this.guess });
  },

  onBackspace() {
    this.guess = this.guess.slice(0, -1);
    this.refreshInputElement();
  },

  onChar(newChar) {
    if (this.guess.length < 5) {
      this.guess = this.guess + newChar;
      this.refreshInputElement();
    }
  },

  refreshInputElement() {
    [...Array(5).keys()].map((index) => {
      let char = this.guess.charAt(index);
      let el = document.getElementById(`input-tile-${index}`);

      if (el) {
        el.children[0].innerText = char;
        if (char === "") {
          el.classList.remove("border-gray-500");
          el.classList.add("border-gray-300");
        } else {
          el.classList.remove("border-gray-300");
          el.classList.add("border-gray-500");
        }
      }
    });
  },
};
