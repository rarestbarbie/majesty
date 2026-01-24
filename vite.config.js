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
                login: resolve(__dirname, 'login.html'),
                lobby: resolve(__dirname, 'lobby.html'),
                play: resolve(__dirname, 'play.html'),
            },
        },
    },
    server: {
        watch: {
            ignored: [
                '/swift/majesty/.build',
                '/swift/majesty/.games',
                '/swift/majesty/Docs',
                '/swift/majesty/Plugins',
                '/swift/majesty/Scripts',
                '/swift/majesty/Sources',
                '/swift/majesty/Tests',
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
