import {
    DiffableListElement,
    UpdateBigInt,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    Resource,
    ResourceNeed,
    ProgressCell,
    TooltipType,
} from './exports.js';

export class ResourceNeedRow implements DiffableListElement<Resource> {
    public readonly id: Resource;
    public readonly node: HTMLAnchorElement;

    private readonly demand: ProgressCell;
    private readonly stockpile: HTMLElement;

    public static get columns(): string[] {
        return [
            "Resource",
            "Demand",
            "Stockpile",
        ];
    }

    constructor(
        need: ResourceNeed,
        owner: GameID,
        demand: TooltipType,
        stockpile: TooltipType
    ) {
        this.id = need.id;
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

        this.node.appendChild(label);
        this.node.appendChild(this.demand.node);
        this.node.appendChild(this.stockpile);
        this.node.dataset['tier'] = need.tier;
    }

    public update(need: ResourceNeed): void {
        UpdateBigInt(this.demand.summary, need.demanded);

        let fraction: number;
        if (need.demanded === 0n) {
            fraction = 0; // Avoid division by zero
        } else if (need.consumed > need.demanded) {
            fraction = 1;
        } else {
            fraction = Number(need.consumed) / Number(need.demanded);
        }

        this.demand.set(fraction * 100);

        UpdateBigInt(this.stockpile, need.acquired);

        if (need.acquired < need.demanded) {
            this.stockpile.dataset['cell'] = 'shortage';
        } else {
            delete this.stockpile.dataset['cell'];
        }
    }
}
