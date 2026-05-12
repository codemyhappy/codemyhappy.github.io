import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  // 设置构建输出目录
  outDir: './docs',
  server: {
    host: '0.0.0.0',
    port: 9002
  }
});