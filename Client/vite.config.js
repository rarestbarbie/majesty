import viteCompression from 'vite-plugin-compression';
import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
    base: '/majesty/',
    publicDir: 'Public',
    build: {
        target: 'esnext',
        outDir: '.build.vite',
        assetsDir: 'assets',
        rollupOptions: {
            input: {
                play: resolve(__dirname, 'index.html'),
                login: resolve(__dirname, 'login.html'),
            },
        },
    },
    plugins: [
        viteCompression({
            // Use a regex to target .js, .css, and .wasm files
            // The `$` ensures it only matches the end of the filename
            filter: /\.(js|css|wasm|html|json)$/i,
            algorithm: 'gzip',
            deleteOriginFile: true,
        })
    ],
});
