import {
    Fortune,
    DiffableListElement,
    Ticker,
    UpdateText,
    UpdatePrice,
} from '../../DOM/exports.js';
import {
    MarketTableEntry,
    ScreenType,
    TooltipType,
} from "../exports.js";

export class MarketTableRow implements DiffableListElement<string> {
    public readonly id: string
    public readonly node: HTMLAnchorElement;
    private readonly name: HTMLElement;
    private readonly price: Ticker;
    private readonly open: HTMLElement;
    private readonly low: HTMLElement;
    private readonly high: HTMLElement;
    private readonly volume: HTMLElement;

    public static get columns(): string[] {
        return [
            "Market",
            "Price",
            "Open",
            "Low",
            "High",
            "Volume"
        ];
    }

    constructor(market: MarketTableEntry) {
        this.id = market.id;
        this.node = document.createElement('a');
        this.name = document.createElement('div');
        this.price = new Ticker(Fortune.Bonus);
        this.open = document.createElement('div');
        this.low = document.createElement('div');
        this.high = document.createElement('div');
        this.volume = document.createElement('div');

        this.name.textContent = market.name;

        this.node.href = `#screen=${ScreenType.Trade}&id=${market.id}`;
        this.node.appendChild(this.name);
        this.node.appendChild(this.price.outer);
        this.node.appendChild(this.open);
        this.node.appendChild(this.low);
        this.node.appendChild(this.high);
        this.node.appendChild(this.volume);

        this.volume.setAttribute('data-tooltip-type', TooltipType.MarketLiquidity);
        this.volume.setAttribute('data-tooltip-arguments', JSON.stringify([market.id]));
    }

    public update(market: MarketTableEntry): void {
        this.price.updatePriceChange(market.price.o, market.price.c, 2);

        UpdatePrice(this.open, market.price.o, 2);
        UpdatePrice(this.low, market.price.l, 2);
        UpdatePrice(this.high, market.price.h, 2);
        UpdateText(this.volume, market.volume.toLocaleString());
    }
}
