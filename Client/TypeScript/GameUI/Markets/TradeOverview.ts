import { StaticList } from '../../DOM/exports.js';
import { ScreenContent } from "../ScreenContent.js";
import { Swift } from "../../Swift.js";
import {
    GameDate
} from "../../GameEngine/exports.js";
import {
    CandleGeometry,
    TradeReport,
    MarketFilter,
    MarketFilterLabel,
    CandlestickChartInterval,
    MarketTableRow,
    MarketTableEntry,
} from '../exports.js';

export class TradeOverview extends ScreenContent {
    private filterlists: [
        StaticList<MarketFilter, string>,
        StaticList<MarketFilter, string>,
    ]
    private history: StaticList<CandleGeometry, GameDate>;
    private markets: StaticList<MarketTableRow, string>;
    private dom?: {
        readonly index: HTMLDivElement;
        readonly filters: [HTMLInputElement, HTMLInputElement];
        readonly panel: HTMLDivElement;
    };

    constructor() {
        super();
        this.filterlists = [
            new StaticList<MarketFilter, string>(document.createElement("ul")),
            new StaticList<MarketFilter, string>(document.createElement("ul")),
        ];

        this.history = new StaticList<CandleGeometry, GameDate>(document.createElement("div"));
        this.history.node.classList.add('candlesticks');

        this.markets = new StaticList<MarketTableRow, string>(document.createElement("div"));
        this.markets.table('Markets', MarketTableRow.columns);
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        let state: TradeReport = Swift.openTrade(
            parameters.get('id'),
            parameters.get('filter')
        );

        if (!this.dom) {
            this.dom = {
                index: document.createElement("div"),
                filters: [
                    document.createElement("input"),
                    document.createElement("input"),
                ],
                panel: document.createElement("div"),
            }

            const stats: HTMLDivElement = document.createElement("div");
            stats.appendChild(this.history.node);
            this.dom.panel.appendChild(stats);
            this.dom.panel.appendChild(this.markets.node);

            this.dom.index.classList.add('tabs');
            for (let i: number = 0; i < this.dom.filters.length; i++) {
                const input: HTMLInputElement = this.dom.filters[i];

                const tab: HTMLDivElement = document.createElement("div");
                const label: HTMLLabelElement = document.createElement("label");
                const content: HTMLDivElement = document.createElement("div");
                const icon: HTMLSpanElement = document.createElement("span");
                icon.textContent = i == 0 ? "🛍️" : "💶";

                const id: string = `market-filterset-${i}`;
                input.type = 'radio';
                input.name = 'market-filterset';
                input.id = id;
                label.htmlFor = id;
                label.appendChild(icon);

                content.classList.add('tabcontent');
                content.appendChild(this.filterlists[i].node);

                tab.appendChild(input);
                tab.appendChild(label);
                tab.appendChild(content);

                this.dom.index.appendChild(tab);
            }
        }

        if (root) {
            root.appendChild(this.dom.index);
            root.appendChild(this.dom.panel);
        }

        this.dom.filters[state.filterlist ?? 0].checked = true;
        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error("TradeOverview not attached");
        }

        //this.dom.controller.abort();
        this.dom.index.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: TradeReport): void {
        if (!this.dom || state.markets.length == 0) {
            return;
        }

        for (let i: number = 0; i < this.dom.filters.length; i++) {
            this.filterlists[i].update(
                state.filterlists[i],
                (label: MarketFilterLabel) => new MarketFilter(label),
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
            // Update the history
            this.history.update(
                state.market.chart.history,
                (interval: CandlestickChartInterval) => new CandleGeometry(interval),
                (interval: CandlestickChartInterval, candle: CandleGeometry) =>
                    candle.update(interval),
            );

            this.history.node.style.setProperty('--y-min', state.market.chart.min.toString());
            this.history.node.style.setProperty('--y-max', state.market.chart.max.toString());
        }
    }
}
