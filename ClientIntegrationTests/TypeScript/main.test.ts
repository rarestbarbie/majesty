import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from 'url';

// Adjust the path to the generated `index.js` which contains the SwiftRuntime
import {
    instantiate,
    InstantiateOptions
} from '../.build.wasm/plugins/PackageToJS/outputs/Package/instantiate.js';
import {
    defaultNodeSetup
} from '../.build.wasm/plugins/PackageToJS/outputs/Package/platforms/node.js';

// Helper to resolve paths relative to the current file
const __filename: string = fileURLToPath(import.meta.url);
const __dirname: string = path.dirname(__filename);

const start: string = path.resolve(__dirname, "../../Client/start.json");
const rules: string = path.resolve(__dirname, "../../Client/rules.json");
const terrain: string = path.resolve(__dirname, "../../Client/terrain.json");

declare global {
    var start: any;
    var rules: any;
    var terrain: any;
}

global.start = JSON.parse(fs.readFileSync(start, 'utf8'));
global.rules = JSON.parse(fs.readFileSync(rules, 'utf8'));
global.terrain = JSON.parse(fs.readFileSync(terrain, 'utf8'));

const options: InstantiateOptions = await defaultNodeSetup({});
await instantiate(options);
