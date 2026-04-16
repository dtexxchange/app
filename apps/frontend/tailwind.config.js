/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#00ff9d',
        'bg-dark': '#0a0b0d',
        'bg-card': '#15171c',
        'text-dim': '#94a3b8',
        'accent-blue': '#3b82f6',
      },
      borderRadius: {
        '12': '12px',
        '24': '24px',
      }
    },
  },
  plugins: [],
}
