
import { io, Socket } from 'socket.io-client';
import { Texture, TextureLoader } from 'three';
import { init } from '../.build.wasm/plugins/PackageToJS/outputs/Package/index.js';
import { PlayerEventID, PlayerMessage } from './Multiplayer/exports.js';
import { Swift } from './Swift.js';
import { Persistence } from './DB/exports.js';
import { Application, GameUI } from './GameUI/exports.js';
import { GameID } from './GameEngine/exports.js';

import * as Firebase from 'firebase/auth';

import '../Stylesheets/main.scss';

declare global {
    interface Window {
        swift: Swift;
    }
}

async function texture(path: string): Promise<Texture> {
    return new Promise<Texture>((resolve, reject) => {
        new TextureLoader().load(path, resolve, undefined, reject);
    });
}

async function json(path: string): Promise<any> {
    const file: Response = await fetch(path);
    return await file.json();
}

async function main(user: Firebase.User): Promise<void> {
    const persistence: Persistence = new Persistence(user);
    const parameters: URLSearchParams = new URLSearchParams(window.location.search);

    const newMap: string | null = parameters.get('new');
    const oldMap: string | null = parameters.get('map');

    const sprites: Promise<Texture> = texture('/majesty/CelestialBodies.png');
    const start: Promise<any> = json('/majesty/start.json');
    const rules: Promise<any> = json('/majesty/rules.json');

    let terrain: any[] | null = null;

    if (oldMap !== null) {
        persistence.currentMap = oldMap;
        terrain = await persistence.loadMap();
    } else {
        console.log(`Creating new map: ${newMap}`);
        persistence.currentMap = newMap ?? 'untitled';
        terrain = await json('/majesty/terrain.json') as any[];
    }

    if (terrain === null) {
        console.error("Failed to load terrain");
        return;
    }

    window.swift = new Swift();
    const application: Application = new Application(persistence, await sprites);

    // Parse path components to determine the current page
    const path: string[] = window.location.pathname.split('/').filter(Boolean);
    const game: string | undefined = path[2];
    if (path[1] == 'mp', game) {
        console.log(`Running in Multiplayer Mode`);

        const mp: Socket<any, any> = io('http://localhost:3000');

        await init();
        await window.swift.ready;

        let ui: GameUI | null = await Swift.load(await start, await rules, terrain);
        if (ui !== null) {
            application.update(ui);
            application.view(0, 10 as GameID);
            application.navigate();
            application.resize();
        } else {
            console.error("Failed to load game");
            return;
        }

        mp.on('designate', () => {
            console.log(`You are the HOST of this game!`);

            const dialog: HTMLDialogElement = document.createElement('dialog');
            const header: HTMLParagraphElement = document.createElement('p');
            const button: HTMLButtonElement = document.createElement('button');

            header.appendChild(document.createTextNode(`You are the HOST of this game!`));
            button.appendChild(document.createTextNode(`Start Game`));

            document.body.appendChild(dialog);
            dialog.appendChild(header);
            dialog.appendChild(button);

            dialog.showModal();

            button.addEventListener('click', () => {
                dialog.close();
                dialog.remove();
                setInterval(() => { Application.move({ id: PlayerEventID.Tick }); }, 100);

                Swift.bind(application);
            });
        });
        mp.on('admit', (admitted: boolean) => {
            if (admitted) {
                console.log(`You have been admitted to the game!`);
            } else {
                console.log(`This game has already started!`);
            }
        });
        mp.on('ended', () => {
            console.log(`The game has ended!`);
        });
        mp.on('push', (event: PlayerMessage) => {
            Swift.push(event.type, BigInt(event.seq));
        });

        Application.mp = mp;

        mp.emit('join', { game: game });

    } else {
        console.log(`Running in Single Player Mode`);

        await init();
        await window.swift.ready;

        console.log(`Launching Game Engine (WebAssembly must be initialized before this!)`);

        // Load the game state from the server.
        let ui: GameUI | null = await Swift.load(await start, await rules, terrain);
        if (ui !== null) {
            application.update(ui);
            application.view(0, 10 as GameID);
            application.navigate();
            application.resize();

            setInterval(() => { Application.move({ id: PlayerEventID.Tick }); }, 100);

            Swift.bind(application);
        } else {
            console.error("Failed to load game");
            return;
        }
    }
}

Firebase.onAuthStateChanged(Persistence.auth, (user: Firebase.User | null) => {
    if (user) {
        main(user);
    } else {
        window.location.href = '/majesty/login';
    }
});
