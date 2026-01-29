import {
    FilterList,
    FilterTabs,
    StaticList,
    Term,
    TermState,
    UpdateText
} from '../../DOM/exports.js';
import { Swift } from '../../Swift.js';
import {
    GameDate
} from '../../GameEngine/exports.js';
import {
    Candlestick,
    CandlestickState,
    TradeReport,
    MarketFilter,
    MarketFilterLabel,
    MarketTableRow,
    MarketTableEntry,
    ScreenType,
    ScreenContent,
    TickRule,
    TickRuleState,
} from '../exports.js';

export class TradeOverview extends ScreenContent {
    private filters: FilterList<MarketFilter, string>[];

    private readonly chartCandles: StaticList<Candlestick, GameDate>;
    private readonly chartTicks: StaticList<TickRule, number>;
    private readonly terms: StaticList<Term, string>;

    private markets: StaticList<MarketTableRow, string>;
    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleName: HTMLHeadingElement;
        readonly chart: HTMLDivElement;
    };

    constructor() {
        super();

        this.filters = [
            new FilterList<MarketFilter, string>('🛍️'),
            new FilterList<MarketFilter, string>('💶'),
        ];

        this.chartCandles = new StaticList<Candlestick, GameDate>(document.createElement('div'));
        this.chartCandles.node.classList.add('candles');

        this.chartTicks = new StaticList<TickRule, number>(document.createElement('div'));
        this.chartTicks.node.classList.add('ticks');

        this.terms = new StaticList<Term, string>(document.createElement('ul'));
        this.terms.node.classList.add('terms');

        this.markets = new StaticList<MarketTableRow, string>(document.createElement('div'));
        this.markets.table('Markets', MarketTableRow.columns);
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        let state: TradeReport = await Swift.openTrade(parameters);

        // otherwise tooltips will be queried against the wrong market
        this.chartCandles.clear();
        this.chartTicks.clear();

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleName: document.createElement('h3'),
                chart: document.createElement('div'),
            }

            this.dom.title.appendChild(this.dom.titleName);

            this.dom.chart.classList.add('tradingview');
            this.dom.chart.appendChild(this.chartCandles.node);
            this.dom.chart.appendChild(this.chartTicks.node);

            const market: HTMLDivElement = document.createElement('div');
            market.setAttribute('data-subscreen', 'Market');
            market.appendChild(this.dom.chart);
            market.appendChild(this.terms.node);

            const upper: HTMLDivElement = document.createElement('div');
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(market);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.markets.node);
            this.dom.panel.classList.add('panel');
        }

        this.dom.index.tabs[state.filterlist ?? 0].checked = true;
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
            throw new Error('TradeOverview not attached');
        }
    }

    public update(state: TradeReport): void {
        if (this.dom === undefined || state.markets.length == 0) {
            return;
        }

        for (let i: number = 0; i < this.dom.index.tabs.length; i++) {
            this.filters[i].update(
                state.filterlists[i],
                (label: MarketFilterLabel) => new MarketFilter(label, ScreenType.Trade),
                () => {},
                state.filter
            );
        }

        this.markets.update(
            state.markets,
            (market: MarketTableEntry) => new MarketTableRow(market),
            (market: MarketTableEntry, row: MarketTableRow) => row.update(market),
            state.market?.id
        );

        UpdateText(this.dom.titleName, state.market?.name ?? '');

        if (state.market !== undefined) {

            this.dom.chart.style.setProperty('--y-min', state.market.chart.min.toString());
            this.dom.chart.style.setProperty('--y-max', state.market.chart.max.toString());
            this.dom.chart.style.setProperty('--y-maxv', state.market.chart.maxv.toString());

            const id: string = state.market.id;

            this.chartCandles.update(
                state.market.chart.history,
                (interval: CandlestickState) => new Candlestick(interval, id),
                (interval: CandlestickState, candle: Candlestick) => candle.update(interval),
            );
            this.chartTicks.update(
                state.market.chart.ticks,
                (state: TickRuleState) => new TickRule(state),
                (state: TickRuleState, tick: TickRule) => tick.update(state),
            );

            this.terms.update(
                state.market.terms,
                (term: TermState) => new Term(term),
                (term: TermState, item: Term) => item.update(term, [id]),
            );
        }
    }
}
