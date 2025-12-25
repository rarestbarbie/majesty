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

    private readonly demanded: ProgressCell;
    private readonly acquired: ProgressCell;
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

        this.demanded = new ProgressCell();
        this.demanded.node.setAttribute('data-tooltip-type', type.tooltipResourceIO);

        this.acquired = new ProgressCell();
        this.acquired.node.setAttribute('data-tooltip-type', type.tooltipStockpile);

        this.price = new Ticker(Fortune.Malus);
        this.price.outer.setAttribute('data-tooltip-type', type.tooltipExplainPrice);

        this.node.appendChild(label);
        this.node.appendChild(this.demanded.node);
        this.node.appendChild(this.acquired.node);
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

        UpdateBigInt(this.demanded.summary, state.demanded);
        this.demanded.set(state.fulfilled * 100);

        UpdateBigInt(this.acquired.summary, state.acquired);

        if (state.stockpile !== undefined) {
            this.acquired.node.classList.remove(CellStyle.Bloody);
            this.acquired.set(state.stockpile * 100);
        } else if (state.fulfilled < 1) {
            this.acquired.node.classList.add(CellStyle.Bloody);
        } else {
            this.acquired.node.classList.remove(CellStyle.Bloody);
        }

        if (state.price !== undefined) {
            this.price.updatePriceChange(state.price.o, state.price.c, 2);
        }
    }

    private configure(): void {
        this.demanded.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.acquired.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.price.outer.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
    }
}
