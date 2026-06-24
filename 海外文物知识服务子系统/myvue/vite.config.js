import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    },
    extensions: ['.mjs', '.js', '.ts', '.jsx', '.tsx', '.json', '.vue']
  },
  server: {
    port: 3000,
    open: true,
    proxy: {
      '/search': { target: 'http://localhost:8085', changeOrigin: true },
      '/user': { target: 'http://localhost:8085', changeOrigin: true },
      '/users': { target: 'http://localhost:8085', changeOrigin: true },
      '/dataviz': { target: 'http://localhost:8085', changeOrigin: true },
      '/knowledge': { target: 'http://localhost:8085', changeOrigin: true }
    }
  }
})
