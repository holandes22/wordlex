export default {
  mounted() {
    this.guess = "";
    this.el.addEventListener("keyboard:clicked", (event) => {
      this.onKey(event.detail.key);
    });
    this.handleEvent("keyboard:reset", () => {
      this.guess = "";
      this.updateInputElement();
    });
    window.addEventListener("keydown", ({ key }) => {
      this.onKey(key);
    });
  },

  updated() {
    this.updateInputElement();
  },

  onKey(key) {
    if (key === "Enter") {
      this.onEnter();
    } else if (key === "Backspace") {
      this.onBackspace();
    } else {
      key = key.toUpperCase();
      if (key.length === 1 && key >= "A" && key <= "Z") {
        this.onChar(key);
      }
    }
  },

  onEnter() {
    this.pushEvent("submit", { guess: this.guess });
  },

  onBackspace() {
    this.guess = this.guess.slice(0, -1);
    this.updateInputElement();
  },

  onChar(newChar) {
    if (this.guess.length < 5) {
      this.guess = this.guess + newChar;
      this.updateInputElement();
    }
  },

  updateInputElement() {
    [...Array(5).keys()].map((index) => {
      let char = this.guess.charAt(index);
      let id = `input-tile-${index}`;
      let el = document.getElementById(id);

      if (el) {
        el.children[0].innerText = char;
        if (char === "") {
          el.classList.remove("border-gray-500");
          el.classList.add("border-gray-300");
        } else {
          el.classList.remove("border-gray-300");
          el.classList.add("border-gray-500");
        }
      } else {
        window.console.error(`Missing input element with id ${id}`);
      }
    });
  },
};
