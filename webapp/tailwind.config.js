/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { 500: '#2563EB', 600: '#1D4ED8', 700: '#1E40AF' },
        school: { blue: '#2563EB', green: '#16A34A', amber: '#D97706', red: '#DC2626' }
      },
      fontFamily: { sans: ['Lexend', 'system-ui', 'sans-serif'] }
    }
  },
  plugins: [require('@tailwindcss/forms')]
};
