import {
    FilterList,
    FilterTabs,
    UpdateText,
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
        readonly header: HTMLElement;
        readonly titleUpper: HTMLHeadingElement;
        readonly titleLower: HTMLHeadingElement;
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
        const filter: string | null = parameters.get('filter');
        const state: PlanetReport = await Swift.openPlanet(
            {
                subject: id !== null ? id : undefined,
                filter: filter !== null ? parseInt(filter) as GameID ?? undefined : undefined
            }
        );

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                header: document.createElement('heading'),
                titleUpper: document.createElement('h3'),
                titleLower: document.createElement('h3'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            };

            this.dom.header.appendChild(this.dom.titleUpper);

            this.dom.panel.appendChild(this.dom.header);
            this.dom.panel.appendChild(this.grid.node);
            this.dom.panel.appendChild(this.dom.titleLower);
            this.dom.panel.appendChild(this.dom.nav);
            this.dom.panel.appendChild(this.dom.stats);
            this.dom.panel.classList.add('panel');

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

        UpdateText(this.dom.titleLower, state.name ?? '');

        if (state.details === undefined) {
            return;
        }

        UpdateText(this.dom.titleUpper, state.details.name ?? '');
        this.grid.update(
            state.entries,
            state.details.open,
            (id: string) => `#screen=Planet&id=${id}`
        );

    }
}
