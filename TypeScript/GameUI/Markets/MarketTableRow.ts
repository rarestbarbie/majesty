import {
    Fortune,
    DiffableListElement,
    Ticker,
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
    private readonly volume: Ticker;
    private readonly velocity: Ticker;

    public static get columns(): string[] {
        return [
            "Market",
            "Price",
            "Volume",
            "Velocity",
        ];
    }

    constructor(market: MarketTableEntry) {
        this.id = market.id;
        this.node = document.createElement('a');
        this.name = document.createElement('div');
        this.price = new Ticker(Fortune.Bonus);
        this.volume = new Ticker(Fortune.Bonus);
        this.velocity = new Ticker(Fortune.Malus);

        this.name.textContent = market.name;

        this.node.href = `#screen=${ScreenType.Trade}&id=${market.id}`;
        this.node.appendChild(this.name);

        const tooltipArguments: string = JSON.stringify([market.id]);

        this.node.appendChild(this.price.outer);
        this.price.outer.setAttribute('data-tooltip-type', TooltipType.MarketPrices);
        this.price.outer.setAttribute('data-tooltip-arguments', tooltipArguments);

        this.node.appendChild(this.volume.outer);
        this.volume.outer.setAttribute('data-tooltip-type', TooltipType.MarketVolume);
        this.volume.outer.setAttribute('data-tooltip-arguments', tooltipArguments);

        this.node.appendChild(this.velocity.outer);
        this.velocity.outer.setAttribute('data-tooltip-type', TooltipType.MarketVelocity);
        this.velocity.outer.setAttribute('data-tooltip-arguments', tooltipArguments);
    }

    public update(market: MarketTableEntry): void {
        this.price.updatePriceChange(market.open, market.close, 2);
        this.volume.updatePriceChange(market.volume_y, market.volume_z, 2);
        this.velocity.updatePriceChange(100 * market.velocity_y, 100 * market.velocity_z, 3);
    }
}
