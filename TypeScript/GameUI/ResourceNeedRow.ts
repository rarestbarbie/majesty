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

    private owner: GameID;

    constructor(
        state: ResourceNeed,
        owner: GameID,
        type: PersistentOverviewType,
    ) {
        this.id = state.id;
        this.node = document.createElement('a');

        const label: HTMLDivElement = document.createElement('div');
        label.textContent = `${state.icon} ${state.name}`;

        this.demand = new ProgressCell();
        this.demand.node.setAttribute('data-tooltip-type', type.tooltipResourceIO);

        this.stockpile = document.createElement('div');
        this.stockpile.setAttribute('data-tooltip-type', type.tooltipStockpile);

        this.price = new Ticker(Fortune.Malus);
        this.price.outer.setAttribute('data-tooltip-type', type.tooltipExplainPrice);

        this.node.appendChild(label);
        this.node.appendChild(this.demand.node);
        this.node.appendChild(this.stockpile);
        this.node.appendChild(this.price.outer);
        this.node.dataset['tier'] = state.tier;

        this.owner = owner;
        this.configure();
    }

    public update(state: ResourceNeed, owner: GameID): void {
        if (this.owner !== owner) {
            this.owner = owner;
            this.configure();
        }

        UpdateBigInt(this.demand.summary, state.demand);

        let fraction: number;
        if (state.demand === 0n) {
            fraction = 0; // Avoid division by zero
        } else if (state.filled > state.demand) {
            fraction = 1;
        } else {
            fraction = Number(state.filled) / Number(state.demand);
        }

        this.demand.set(fraction * 100);

        if (state.stockpile !== undefined) {
            UpdateBigInt(this.stockpile, state.stockpile);
        } else {
            UpdateText(this.stockpile, '');
        }

        if (state.filled < state.demand) {
            this.stockpile.classList.add(CellStyle.Bloody);
        } else {
            this.stockpile.classList.remove(CellStyle.Bloody);
        }

        if (state.price !== undefined) {
            this.price.updatePriceChange(state.price.o, state.price.c, 2);
        }
    }

    private configure(): void {
        this.demand.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.stockpile.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.price.outer.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
    }
}
