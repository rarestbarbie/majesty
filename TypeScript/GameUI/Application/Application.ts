import {
    Texture,
    SRGBColorSpace,
    WebGLRenderer
} from 'three';
import { Persistence } from '../../DB/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import { PlayerEvent, PlayerEventID } from '../../Multiplayer/exports.js';
import {
    CelestialView,
    CelestialViewState,
    ContextMenuType,
    Clock,
    DeveloperToolsPanel,
    GameUI,
    Screen,
    ScreenType,
    TooltipType,
    Minimap,
    NavigatorTile,
    NavigatorState,
    MinimapLayer,
} from '../exports.js';
import { Swift } from '../../Swift.js';
import { Socket } from "socket.io-client";
import {
    ContextMenu,
    ContextMenuState,
    Tooltip
} from '../../DOM/exports.js';

export class Application {
    public static mp?: Socket<any, any>;


    private readonly tile: NavigatorTile;
    private readonly minimap: Minimap;
    private readonly screen: Screen;
    private readonly clock: Clock;
    private readonly tabs: {
        production: HTMLElement;
        infrastructure: HTMLElement;
        population: HTMLElement;
        budget: HTMLElement;
        trade: HTMLElement;
    };
    private readonly main: HTMLElement;

    private views: [CelestialView?, CelestialView?];

    private readonly contextMenu: ContextMenu;
    private readonly tooltip: Tooltip<TooltipType>;
    private readonly devtools: DeveloperToolsPanel;

    public readonly persistence: Persistence;
    public readonly renderer: WebGLRenderer;
    public readonly sprites: Texture;

    private static _tab(type: ScreenType, id: string): HTMLElement {
        const tab: HTMLAnchorElement = document.createElement('a');
        const name: HTMLElement = document.createElement('div');
        name.innerText = type;
        tab.appendChild(name);
        tab.href = `#screen=${type}`
        tab.id = id;
        return tab;
    }

    public constructor(persistence: Persistence, sprites: Texture) {
        this.persistence = persistence;
        this.renderer = new WebGLRenderer({ antialias: true });
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.sprites = sprites;
        this.sprites.colorSpace = SRGBColorSpace;
        //this.sprites.magFilter = LinearMipmapNearestFilter;

        this.clock = new Clock();
        this.clock.pause.onclick = () => { Application.move({ id: PlayerEventID.Pause }); };
        this.clock.faster.onclick = () => { Application.move({ id: PlayerEventID.Faster }); };
        this.clock.slower.onclick = () => { Application.move({ id: PlayerEventID.Slower }); };

        this.tile = new NavigatorTile();
        this.minimap = new Minimap();
        this.screen = new Screen();
        this.tabs = {
            production: Application._tab(ScreenType.Production, 'production-tab'),
            infrastructure: Application._tab(ScreenType.Infrastructure, 'infrastructure-tab'),
            population: Application._tab(ScreenType.Population, 'population-tab'),
            budget: Application._tab(ScreenType.Budget, 'budget-tab'),
            trade: Application._tab(ScreenType.Trade, 'trade-tab')
        };

        this.main = document.createElement('main');

        const hud: {
            node: HTMLDivElement;
            interface: HTMLDivElement;
            developer: DeveloperToolsPanel;
        } = {
            node: document.createElement('div'),
            interface: document.createElement('div'),
            developer: new DeveloperToolsPanel(this),
        };

        const header: HTMLElement = document.createElement('header');
        header.id = 'tabs';
        header.appendChild(this.tabs.production);
        header.appendChild(this.tabs.infrastructure);
        header.appendChild(this.tabs.population);
        header.appendChild(this.tabs.budget);
        header.appendChild(this.tabs.trade);

        const devtools: HTMLButtonElement = document.createElement('button');
        devtools.textContent = 'Dev Tools';
        devtools.id = 'developer-tools-toggle';
        devtools.addEventListener('click', () => {
            this.devtools.toggle();
        });

        hud.interface.appendChild(header);
        hud.interface.appendChild(this.clock.node);
        hud.interface.appendChild(this.tile.node);
        hud.interface.appendChild(this.minimap.node);
        hud.interface.appendChild(devtools);

        hud.node.id = 'hud';
        hud.node.appendChild(hud.interface);
        hud.node.appendChild(hud.developer.node);

        this.contextMenu = new ContextMenu(
            (action, argumentList) => Swift.call(action, argumentList)
        );
        this.contextMenu.node.id = 'context-menu';

        this.tooltip = new Tooltip<TooltipType>();
        this.tooltip.node.id = 'tooltip';

        this.devtools = hud.developer;

        document.body.appendChild(this.renderer.domElement);
        document.body.appendChild(this.main);
        document.body.appendChild(hud.node);
        document.body.appendChild(this.contextMenu.node);
        document.body.appendChild(this.tooltip.node);

        this.screen.attach(document.body);

        this.views = [undefined, undefined];

        this.bindEventHandlers();

        const animate = () => {
            requestAnimationFrame(animate);
            this.draw();
        };

        animate();
    }

    public navigate() {
        const action: URLSearchParams = new URLSearchParams(window.location.hash.substring(1));

        const screen: string | null = action.get('screen');
        if (screen !== null) {
            switch (screen) {
            case ScreenType.Planet:
                this.screen.open(ScreenType.Planet, action);
                break;
            case ScreenType.Infrastructure:
                this.screen.open(ScreenType.Infrastructure, action);
                break;
            case ScreenType.Production:
                this.screen.open(ScreenType.Production, action);
                break;
            case ScreenType.Population:
                this.screen.open(ScreenType.Population, action);
                break;
            case ScreenType.Budget:
                this.screen.open(ScreenType.Budget, action);
                break;
            case ScreenType.Trade:
                this.screen.open(ScreenType.Trade, action);
                break;
            case '_close':
                this.screen.close();
                break;
            }

            return;
        }

        const planet: GameID | null = parseInt(action.get('planet') ?? '', 10) as GameID | null;
        if (planet) {
            this.focus(
                planet,
                action.get('layer') as MinimapLayer | null,
                action.get('cell'),
            );
            return;
        }
    }

    public resize() {
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        for (const view of this.views) {
            view?.resize();
        }
    }

    private draw() {
        this.devtools.draw();

        for (const view of this.views) {
            view?.draw(this.renderer);
        }
    };

    public update(state: GameUI) {
        this.clock.update(state);
        this.tile.update(state.navigator?.tile);
        this.minimap.update(state.navigator);
        this.screen.update(state.screen);

        for (const i of [0, 1]) {
            const view: CelestialViewState | null = state.views[i];
            if (view !== null) {
                this.views[i]?.update(view);
            }
        }

        // Update the active tooltip content with the new state.
        if (this.tooltip.source) {
            this.tooltip.show(
                Swift.tooltip(this.tooltip.source.type, this.tooltip.source.arguments)
            );
        }
    }

    public focus(planet: GameID, layer: MinimapLayer | null, cell: string | null) {
        const state: NavigatorState = Swift.minimap(planet, layer, cell);

        this.tile.update(state?.tile);
        this.minimap.update(state);

        this.devtools.refresh();

        for (const view of this.views) {
            view?.select(planet);
        }
    }

    public view(index: number, system: GameID | null) {
        this.views[index]?.detach();

        if (system === null) {
            delete this.views[index];
        } else {
            const view: CelestialView = new CelestialView(this, index, system);
            view.attach(this.main);
            view.update(Swift.view(index, system));
            this.views[index] = view;
        }

        for (const view of this.views) {
            view?.resize();
        }
    }

    public static move(event: PlayerEvent) {
        if (Application.mp) {
            Application.mp.emit('move', event);
        } else {
            Swift.push(event, 0n);
        }
    }

    private bindEventHandlers(): void {
        window.addEventListener('hashchange', this.navigate.bind(this));
        window.addEventListener('resize', this.resize.bind(this));

        document.addEventListener('mouseover', (event) => {
            const owner: HTMLElement | null = (event.target as HTMLElement).closest(
                '[data-tooltip-arguments]'
            );

            if (!owner) {
                return;
            }

            const unparsed: string | null = owner.getAttribute('data-tooltip-arguments');
            const type: TooltipType = owner.getAttribute('data-tooltip-type') as TooltipType;
            const list: any[] = unparsed ? JSON.parse(unparsed) : [];

            this.tooltip.show(Swift.tooltip(type, list));
            this.tooltip.source = { arguments: list, type: type };
        });

        document.addEventListener('mousemove', (event) => {
            this.tooltip.move(event, document.body.getBoundingClientRect());
        });

        document.addEventListener('mouseout', (event) => {
            const owner: HTMLElement | null = (event.target as HTMLElement).closest(
                '[data-tooltip-arguments]'
            );
            if (owner) {
                this.tooltip.hide();
                this.tooltip.source = undefined;
            }
        });

        document.addEventListener('contextmenu', (event) => {
            const menuOwner: HTMLElement | null = (event.target as HTMLElement).closest(
                '[data-menu-type]'
            );

            if (menuOwner !== null) {
                event.preventDefault();
                const type: ContextMenuType = menuOwner.getAttribute(
                    'data-menu-type'
                ) as ContextMenuType;
                const argumentsText: string | null = menuOwner.getAttribute(
                    'data-menu-arguments'
                );
                const argumentsList: any[] = argumentsText ? JSON.parse(argumentsText) : [];
                const contextMenu: ContextMenuState = Swift.contextMenu(type, argumentsList);
                this.contextMenu.show(contextMenu.items, event.clientX, event.clientY);
                return;
            } else {
                this.contextMenu.hide();
            }

            const target: HTMLElement | null = (event.target as HTMLElement).closest(
                '[data-cr-destination]'
            );
            if (target !== null) {
                event.preventDefault();
                window.location.hash = `#${target.getAttribute('data-cr-destination')}`;
                this.navigate();
            }
        });

        document.addEventListener('mousedown', (event) => {
            if (event.button !== 0) {
                return;
            }

            const target: HTMLElement | null = (event.target as HTMLElement).closest(
                '[data-cl-destination]'
            );

            if (target !== null) {
                event.preventDefault();
                window.location.hash = `#${target.getAttribute('data-cl-destination')}`;
                this.navigate();
            }
        });
        document.addEventListener('click', (event) => {
            if (this.contextMenu.isOpen && !this.contextMenu.node.contains(event.target as Node)) {
                this.contextMenu.hide();
            }
        });
    }
}
