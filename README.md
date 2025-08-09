## Running the Client

The client has TypeScript and Swift components.

To build the Swift (WebAssembly) component:

```bash
cd Client
swift package \
    --scratch-path .build.wasm \
    --swift-sdk wasm32-unknown-wasi \
    js -c release
```

The `--scratch-path` is important — this path is hard-coded into the TypeScript sources, and if
the WebAssembly and generated JavaScript files are not there, Vite won’t be able to link them
with the rest of the app.

To build and run the TypeScript component:

```bash
npx vite
```

## Running the Server

The server is an incredibly basic Socket.IO relay. All game logic is in the client.

To build and run the server:

```bash
npx tsc && node build/Server.js
```

The server listens on port 3000.


## Running the Integration Tests

```bash
cd ClientIntegrationTests
npx tsc
npm test
```
