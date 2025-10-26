/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "../lib/**/*.{heex,ex,html,html.eex,leex}",
    "./js/**/*.js",
    "./css/**/*.css"
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#2563eb", // синий
          light: "#3b82f6",
          dark: "#1e40af",
        },
        neutral: {
          light: "#f3f4f6",
          dark: "#111827",
        },
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui'],
      },
    },
  },
  plugins: [],
}
