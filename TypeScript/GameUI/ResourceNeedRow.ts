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
    PersistentOverviewType,
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
        type: PersistentOverviewType,
        owner: GameID,
    ) {
        this.id = need.id;
        this.node = document.createElement('a');

        const label: HTMLDivElement = document.createElement('div');
        label.textContent = `${need.icon} ${need.name}`;

        this.demand = new ProgressCell();
        this.demand.node.setAttribute('data-tooltip-type', type.tooltipResourceIO);
        this.demand.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.id]),
        );

        this.stockpile = document.createElement('div');
        this.stockpile.setAttribute('data-tooltip-type', type.tooltipStockpile);
        this.stockpile.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.id]),
        );

        this.price = new Ticker(Fortune.Malus);
        this.price.outer.setAttribute('data-tooltip-type', type.tooltipExplainPrice);
        this.price.outer.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, need.id]),
        );

        this.node.appendChild(label);
        this.node.appendChild(this.demand.node);
        this.node.appendChild(this.stockpile);
        this.node.appendChild(this.price.outer);
        this.node.dataset['tier'] = need.tier;
    }

    public update(need: ResourceNeed): void {
        UpdateBigInt(this.demand.summary, need.demand);

        let fraction: number;
        if (need.demand === 0n) {
            fraction = 0; // Avoid division by zero
        } else if (need.filled > need.demand) {
            fraction = 1;
        } else {
            fraction = Number(need.filled) / Number(need.demand);
        }

        this.demand.set(fraction * 100);

        if (need.stockpile !== undefined) {
            UpdateBigInt(this.stockpile, need.stockpile);
        } else {
            UpdateText(this.stockpile, '');
        }

        if (need.filled < need.demand) {
            this.stockpile.classList.add(CellStyle.Bloody);
        } else {
            this.stockpile.classList.remove(CellStyle.Bloody);
        }

        if (need.price !== undefined) {
            this.price.updatePriceChange(need.price.o, need.price.c, 2);
        }
    }
}
