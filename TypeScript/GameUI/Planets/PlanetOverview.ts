import {
    FilterList,
    FilterTabs,
    StaticList,
    Term,
    TermState,
    UpdateText,
} from '../../DOM/exports.js';
import {
    ScreenContent,
    HexGrid,
    PlanetReport,
    PlanetFilter,
    PlanetFilterLabel,
    PlanetMapLayerSelector,
    ScreenType,
} from '../exports.js';
import { Swift } from '../../Swift.js';

export class PlanetOverview extends ScreenContent {
    private readonly filters: FilterList<PlanetFilter, string>[];
    private readonly layers: StaticList<PlanetMapLayerSelector, string>;
    private readonly grid: HexGrid;

    private readonly terms: StaticList<Term, string>;

    private layerShown?: string;
    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly header: HTMLElement;
        readonly layers: HTMLElement;
        readonly titleUpper: HTMLHeadingElement;
        readonly titleLower: HTMLHeadingElement;
        readonly stats: HTMLDivElement;
    };

    constructor() {
        super();
        this.filters = [new FilterList<PlanetFilter, string>('🪐')];
        this.layers = new StaticList<PlanetMapLayerSelector, string>(
            document.createElement('ul')
        );
        this.grid = new HexGrid();

        this.terms = new StaticList<Term, string>(document.createElement('ul'));
        this.terms.node.classList.add('terms');
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        const state: PlanetReport = await Swift.openPlanet(parameters);

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                header: document.createElement('heading'),
                layers: document.createElement('nav'),
                titleUpper: document.createElement('h3'),
                titleLower: document.createElement('h3'),
                stats: document.createElement('div'),
            };

            const panorama: HTMLElement = document.createElement('div');
            panorama.classList.add('panorama');
            panorama.appendChild(this.dom.layers);
            panorama.appendChild(this.grid.node);

            this.dom.header.appendChild(this.dom.titleUpper);
            this.dom.layers.appendChild(this.layers.node);

            this.dom.panel.appendChild(this.dom.header);
            this.dom.panel.appendChild(panorama);
            this.dom.panel.appendChild(this.dom.titleLower);
            this.dom.panel.appendChild(this.dom.stats);
            this.dom.panel.classList.add('panel');

            this.dom.stats.classList.add('stats');

        } else {
            this.dom.stats.replaceChildren();
        }

        this.dom.stats.appendChild(this.terms.node);

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
        if (this.layerShown !== state.details.open) {
            this.layerShown = state.details.open;
            this.grid.switch();
        }
        const id: string = state.details.id;
        this.grid.update(
            state.entries,
            state.details.open,
            (id: string) => `#screen=${ScreenType.Planet}&id=${id}`,
            id
        );

        this.layers.allocate(
            state.layers,
            (layer: string) => new PlanetMapLayerSelector(layer, ScreenType.Planet),
            state.details.open
        );

        this.terms.update(
            state.details.terms,
            (term: TermState) => new Term(term),
            (term: TermState, item: Term) => item.update(term, [id]),
        );
    }
}
