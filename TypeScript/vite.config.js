import viteCompression from 'vite-plugin-compression';
import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
    base: '/majesty/',
    publicDir: '../Public',
    resolve: {
        alias: {
            '@bjorn3/browser_wasi_shim': resolve(__dirname, 'node_modules/@bjorn3/browser_wasi_shim')
        }
    },
    build: {
        target: 'esnext',
        outDir: '.build.vite',
        assetsDir: 'assets',
        rollupOptions: {
            input: {
                login: resolve(__dirname, 'login.html'),
                lobby: resolve(__dirname, 'lobby.html'),
                play: resolve(__dirname, 'play.html'),
            },
        },
    },
    server: {
        watch: {
            ignored: [
            ],
        },
        headers: {
            "Cross-Origin-Opener-Policy": "same-origin",
            "Cross-Origin-Embedder-Policy": "require-corp",
        },
    },
    plugins: [
        viteCompression({
            // Use a regex to target .js, .css, and .wasm files
            // The `$` ensures it only matches the end of the filename
            filter: /\.(js|css|wasm|json)$/i,
            algorithm: 'gzip',
            deleteOriginFile: true,
        })
    ],
});
