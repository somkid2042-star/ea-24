import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import tailwindcss from '@tailwindcss/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  server: {
    host: '0.0.0.0',
  },
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router',
      'apexcharts',
      'react-apexcharts',
      'preline',
      'react-icons/lu',
    ],
  },
});
