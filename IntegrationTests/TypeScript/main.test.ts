import * as fs from 'fs';
import * as path from 'path';
import * as msgpack from 'msgpackr';
import { fileURLToPath } from 'url';

// Adjust the path to the generated `index.js` which contains the SwiftRuntime
import {
    instantiate,
    InstantiateOptions
} from '../.build.wasm/plugins/PackageToJS/outputs/Package/instantiate.js';
import {
    defaultNodeSetup,
    createDefaultWorkerFactory
} from '../.build.wasm/plugins/PackageToJS/outputs/Package/platforms/node.js';

// Helper to resolve paths relative to the current file
const __filename: string = fileURLToPath(import.meta.url);
const __dirname: string = path.dirname(__filename);
const __root: string = path.resolve(__dirname, "../../");

const start: string = path.resolve(__root, "Public/start.json");
const rules: string = path.resolve(__root, "Public/rules.json");
const terrain: string = path.resolve(__root, "Public/terrain.json");

interface IntegrationTestFile {
    name: string;
    save: object;
}

declare global {
    var start: any;
    var rules: any;
    var terrain: any;
    var outputs: IntegrationTestFile[];
}

global.start = JSON.parse(fs.readFileSync(start, 'utf8'));
global.rules = JSON.parse(fs.readFileSync(rules, 'utf8'));
global.terrain = JSON.parse(fs.readFileSync(terrain, 'utf8'));

const options: InstantiateOptions = await defaultNodeSetup(
    {
        spawnWorker: createDefaultWorkerFactory()
    }
);
await instantiate(options);

console.log("Integration tests finished, writing outputs...");
for (const output of global.outputs) {
    const file: string = path.resolve(__root, output.name + ".msgpack");
    fs.writeFileSync(file, msgpack.encode(output.save), 'utf8');
    console.log(`Wrote output to '${file}'`);
}
