/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#fef6ee',
          100: '#fde9d7',
          200: '#facfae',
          300: '#f7ae7a',
          400: '#f38244',
          500: '#f0601f',
          600: '#e14615',
          700: '#ba3213',
          800: '#942918',
          900: '#782416',
          950: '#410f09',
        },
        pepper: {
          green: '#2d5016',
          red: '#dc2626',
          black: '#1a1a1a',
          gold: '#fbbf24',
        }
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
      }
    },
  },
  plugins: [],
}
