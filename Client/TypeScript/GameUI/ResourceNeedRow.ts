import {
    DiffableListElement,
    Fortune,
    Ticker,
    UpdateBigInt,
    UpdateText,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    CellStyle,
    ResourceNeed,
    ProgressCell,
    TooltipType,
} from './exports.js';

export class ResourceNeedRow implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLAnchorElement;

    private readonly demand: ProgressCell;
    private readonly stockpile: HTMLElement;
    private readonly price: Ticker;

    public static get columns(): string[] {
        return [
            "Resource",
            "Demand",
            "Stockpile",
            "Price",
        ];
    }

    constructor(
        need: ResourceNeed,
        owner: GameID,
        demand: TooltipType,
        stockpile: TooltipType,
        explainPrice: TooltipType,
    ) {
        this.id = `${need.id}${need.tier}`;
        this.node = document.createElement('a');

        const label: HTMLDivElement = document.createElement('div');
        label.textContent = `${need.icon} ${need.name}`;

        this.demand = new ProgressCell();
        this.demand.node.setAttribute('data-tooltip-type', demand);
        this.demand.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.tier, need.id]),
        );

        this.stockpile = document.createElement('div');
        this.stockpile.setAttribute('data-tooltip-type', stockpile);
        this.stockpile.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.tier, need.id]),
        );

        this.price = new Ticker(Fortune.Malus);
        this.price.outer.setAttribute('data-tooltip-type', explainPrice);
        this.price.outer.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.tier, need.id]),
        );

        this.node.appendChild(label);
        this.node.appendChild(this.demand.node);
        this.node.appendChild(this.stockpile);
        this.node.appendChild(this.price.outer);
        this.node.dataset['tier'] = need.tier;
    }

    public update(need: ResourceNeed): void {
        UpdateBigInt(this.demand.summary, need.unitsDemanded);

        let fraction: number;
        if (need.unitsDemanded === 0n) {
            fraction = 0; // Avoid division by zero
        } else if (need.unitsConsumed > need.unitsDemanded) {
            fraction = 1;
        } else {
            fraction = Number(need.unitsConsumed) / Number(need.unitsDemanded);
        }

        this.demand.set(fraction * 100);

        if (need.unitsAcquired !== undefined) {
            UpdateBigInt(this.stockpile, need.unitsAcquired);
        } else {
            UpdateText(this.stockpile, '');
        }

        if (need.unitsConsumed < need.unitsDemanded) {
            this.stockpile.classList.add(CellStyle.Bloody);
        } else {
            this.stockpile.classList.remove(CellStyle.Bloody);
        }

        if (need.priceAtMarket !== undefined) {
            this.price.updatePriceChange(need.priceAtMarket.o, need.priceAtMarket.c, 2);
        } else if (need.price !== undefined) {
            this.price.updateBigIntChange(need.price.o, need.price.c);
        }
    }
}
