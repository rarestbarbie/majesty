import {
    FilterList,
    FilterTabs,
    StaticList,
    Term,
    TermState,
    UpdateText,
} from '../../DOM/exports.js';
import {
    GameID,
    GameDate
} from '../../GameEngine/exports.js';
import {
    ScreenContent,
    HexGrid,
    LineChart,
    PlanetReport,
    PlanetFilter,
    PlanetFilterLabel,
    PlanetMapLayerSelector,
    ScreenType,
    PieChart,
    TooltipType,
} from '../exports.js';
import { Swift } from '../../Swift.js';

export class PlanetOverview extends ScreenContent {
    private readonly filters: FilterList<PlanetFilter, string>[];
    private readonly layers: StaticList<PlanetMapLayerSelector, string>;
    private readonly grid: HexGrid;

    private readonly terms: StaticList<Term, string>;
    private readonly produced: PieChart<number>;
    private readonly consumed: PieChart<number>;
    private readonly gdp: PieChart<string>;
    private readonly gdpHistorical: LineChart;

    private layerShown?: string;
    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly header: HTMLElement;
        readonly layers: HTMLElement;
        readonly titleUpper: HTMLHeadingElement;
        readonly titleLower: HTMLHeadingElement;
        readonly details: HTMLDivElement;
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

        this.produced = new PieChart<number>(TooltipType.TileResourceProduced);
        this.consumed = new PieChart<number>(TooltipType.TileResourceConsumed);
        this.gdp = new PieChart<string>(TooltipType.TileIndustry);
        this.gdpHistorical = new LineChart();
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
                details: document.createElement('div'),
                stats: document.createElement('div'),
            };

            const panorama: HTMLElement = document.createElement('div');
            panorama.classList.add('panorama');
            panorama.appendChild(this.dom.layers);
            panorama.appendChild(this.grid.node);

            this.dom.header.appendChild(this.dom.titleUpper);
            this.dom.layers.appendChild(this.layers.node);

            this.dom.stats.classList.add('stats');

            this.dom.panel.appendChild(this.dom.header);
            this.dom.panel.appendChild(panorama);
            this.dom.panel.appendChild(this.dom.titleLower);
            this.dom.panel.appendChild(this.dom.details);
            this.dom.panel.classList.add('panel');

            this.dom.details.classList.add('details');
        } else {
            this.dom.details.replaceChildren();
            this.dom.stats.replaceChildren();
        }

        const charts: [PieChart<any>, string][] = [
            [this.gdp, 'Industries'],
            [this.produced, 'Production'],
            [this.consumed, 'Consumption'],
        ];

        const figures: HTMLDivElement = document.createElement('div');
        figures.classList.add('pie-charts');

        for (const [chart, label] of charts) {
            const container: HTMLElement = document.createElement('figure');
            const caption: HTMLElement = document.createElement('figcaption');
            caption.textContent = label;
            container.appendChild(caption);
            container.appendChild(chart.node);
            figures.appendChild(container);
        }

        this.dom.stats.appendChild(this.terms.node);
        this.dom.stats.appendChild(figures);

        this.dom.details.appendChild(this.gdpHistorical.node);
        this.dom.details.appendChild(this.dom.stats);
        this.dom.details.setAttribute('data-subscreen', 'Region');

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

        this.produced.update(state.details.produced ?? [], id);
        this.consumed.update(state.details.consumed ?? [], id);
        this.gdp.update(state.details.gdp ?? [], id);
        this.gdpHistorical.update(state.details.gdpGraph, id);
    }
}
