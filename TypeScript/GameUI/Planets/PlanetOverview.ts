import {
    FilterList,
    FilterTabs,
} from '../../DOM/exports.js';
import {
    ScreenContent,
    HexGrid,
    MinimapLayer,
    PlanetReport,
    PlanetFilter,
    PlanetFilterLabel,
    ScreenType,
} from '../exports.js';
import { Swift } from '../../Swift.js';
import { GameID } from '../../GameEngine/exports.js';

export class PlanetOverview extends ScreenContent {
    private readonly filters: FilterList<PlanetFilter, string>[];
    private readonly grid: HexGrid;

    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleName: HTMLHeadingElement;
        readonly stats: HTMLDivElement;
        readonly nav: HTMLElement;
    };

    constructor() {
        super();
        this.filters = [
            new FilterList<PlanetFilter, string>('🪐'),
        ];
        this.grid = new HexGrid();
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        const id: string | null = parameters.get('id');
        const state: PlanetReport = await Swift.openPlanet(
            {
                subject: id !== null ? parseInt(id) as GameID ?? undefined : undefined
            }
        );

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleName: document.createElement('h3'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            };

            this.dom.title.appendChild(this.dom.titleName);
            this.dom.title.appendChild(this.dom.nav);

            const upper: HTMLDivElement = document.createElement('div');
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.grid.node);
            this.dom.panel.classList.add('panel');
            this.dom.panel.classList.add('planet-overview');

            this.dom.stats.classList.add('stats');
        } else {
            this.dom.stats.replaceChildren();
            this.dom.nav.replaceChildren();
        }

        this.dom.index.tabs[state.filterlist].checked = true;
        this.update(state);
    }

    public override attach(root: HTMLElement): void {
        if (this.dom !== undefined) {
            root.appendChild(this.dom.index.node);
            root.appendChild(this.dom.panel);
        }
    }
    public override detach(): void {
        if (this.dom !== undefined) {
            this.dom.index.node.remove();
            this.dom.panel.remove();
            this.dom = undefined;
        } else {
            throw new Error('PlanetOverview not attached');
        }
    }

    public update(state: PlanetReport): void {
        if (this.dom === undefined) {
            return;
        }

        for (let i: number = 0; i < this.dom.index.tabs.length; i++) {
            this.filters[i].update(
                state.filterlists[i],
                (label: PlanetFilterLabel) => new PlanetFilter(
                    label,
                    ScreenType.Planet
                ),
                () => {},
                state.filter
            );
        }

        this.grid.update(state.entries, MinimapLayer.Terrain);
    }
}
