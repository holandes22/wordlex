// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  darkMode: "class",
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      keyframes: {
        flip: {
          "20%, 40%": {
            transform: "rotateY(90deg) ",
          },
        },
        shake: {
          "10%, 90%": {
            transform: "translate3d(-1px, 0, 0)",
          },
          "20%, 80%": {
            transform: "translate3d(2px, 0, 0)",
          },
          "30%, 50%, 70%": {
            transform: "translate3d(-4px, 0, 0)",
          },
          "40%, 60%": {
            transform: "translate3d(4px, 0, 0)",
          },
        },
      },
      animation: {
        shake: "shake 0.5s ease-in-out",
        flip: "flip 0.8s ease-in-out",
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
