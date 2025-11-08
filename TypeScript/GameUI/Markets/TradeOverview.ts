import {
    FilterList,
    FilterTabs,
    StaticList
} from '../../DOM/exports.js';
import { ScreenContent } from '../Application/ScreenContent.js';
import { Swift } from '../../Swift.js';
import {
    GameDate
} from '../../GameEngine/exports.js';
import {
    CandleGeometry,
    TradeReport,
    MarketFilter,
    MarketFilterLabel,
    CandlestickChartInterval,
    MarketTableRow,
    MarketTableEntry,
    ScreenType,
} from '../exports.js';

export class TradeOverview extends ScreenContent {
    private filters: FilterList<MarketFilter, string>[];
    private history: StaticList<CandleGeometry, GameDate>;
    private markets: StaticList<MarketTableRow, string>;
    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
    };

    constructor() {
        super();

        this.filters = [
            new FilterList<MarketFilter, string>('🛍️'),
            new FilterList<MarketFilter, string>('💶'),
        ];

        this.history = new StaticList<CandleGeometry, GameDate>(document.createElement('div'));
        this.history.node.classList.add('candlesticks');

        this.markets = new StaticList<MarketTableRow, string>(document.createElement('div'));
        this.markets.table('Markets', MarketTableRow.columns);
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        let state: TradeReport = Swift.openTrade(
            {
                subject: parameters.get('id') ?? undefined,
                filter: parameters.get('filter') ?? undefined,
            }
        );

        if (!this.dom) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
            }

            const upper: HTMLDivElement = document.createElement('div');
            upper.appendChild(this.history.node);
            upper.classList.add('upper');

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.markets.node);
            this.dom.panel.classList.add('panel');
        }

        if (root) {
            root.appendChild(this.dom.index.node);
            root.appendChild(this.dom.panel);
        }

        this.dom.index.tabs[state.filterlist ?? 0].checked = true;
        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error('TradeOverview not attached');
        }

        //this.dom.controller.abort();
        this.dom.index.node.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: TradeReport): void {
        if (!this.dom || state.markets.length == 0) {
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

        if (state.market) {
            this.history.update(
                state.market.chart.history,
                (interval: CandlestickChartInterval) => new CandleGeometry(interval),
                (interval: CandlestickChartInterval, candle: CandleGeometry) =>
                    candle.update(interval),
            );

            this.history.node.style.setProperty('--y-min', state.market.chart.min.toString());
            this.history.node.style.setProperty('--y-max', state.market.chart.max.toString());
            this.history.node.style.setProperty('--y-maxv', state.market.chart.maxv.toString());
        }
    }
}
