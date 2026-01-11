/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class', // Enable class-based dark mode
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#faf8f3',
          100: '#f5f0e6',
          200: '#e8dcc4',
          300: '#d4bc8f',
          400: '#c19a5c',
          500: '#b4813d',
          600: '#a66d31',
          700: '#8a552a',
          800: '#704628',
          900: '#5c3b23',
          950: '#321e11',
        },
        pepper: {
          // Black pepper tones
          black: '#2c2420',
          darkBrown: '#3d2e23',
          mediumBrown: '#5c4033',
          lightBrown: '#8b6f47',
          // Sri Lankan spice colors
          cinnamon: '#b87333',
          gold: '#d4a574',
          earth: '#8b7355',
          // Accent colors
          sriLankaGreen: '#006747', // Sri Lankan flag green
          sriLankaOrange: '#ff6b35', // Sri Lankan saffron/orange
          harvest: '#e8a75d',
        },
        // Role-specific colors updated
        farmer: {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
        },
        exporter: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        admin: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#a855f7',
          600: '#9333ea',
          700: '#7e22ce',
          800: '#6b21a8',
          900: '#581c87',
        }
      },
      backgroundImage: {
        'pepper-texture': "url('/images/pepper-texture.png')",
        'gradient-pepper': 'linear-gradient(135deg, #5c4033 0%, #2c2420 100%)',
        'gradient-warm': 'linear-gradient(135deg, #d4a574 0%, #b87333 100%)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
        'shimmer': 'shimmer 2s linear infinite',
      },
      keyframes: {
        shimmer: {
          '0%': { backgroundPosition: '-1000px 0' },
          '100%': { backgroundPosition: '1000px 0' },
        }
      }
    },
  },
  plugins: [],
}
