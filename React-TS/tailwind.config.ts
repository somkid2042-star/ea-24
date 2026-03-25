/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('preline/plugin'),
  ],
  colors: {
    primary: '#3b82f6',
    'default-500': '#6b7280',
    'default-800': '#1f2937',
    'default-200': '#e5e7eb',
    // add any other custom colors you need
  },
};
