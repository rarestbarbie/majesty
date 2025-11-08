## Running the Client

The client has TypeScript and Swift components.

To build the Swift (WebAssembly) component:

```bash
Scripts/Build -w
```

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
cd IntegrationTests
npx tsc
npm test
```
