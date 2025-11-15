import {
    DiffableListElement,
    Fortune,
    Ticker,
    UpdateBigInt,
    UpdateText,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import { PersistentOverviewType, ResourceSale, TooltipType } from './exports.js';

export class ResourceSaleBox implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLAnchorElement;

    private readonly units: HTMLElement;
    private readonly price: Ticker;
    private readonly subtitle: HTMLElement;

    private owner: GameID;

    constructor(
        state: ResourceSale,
        owner: GameID,
        type: PersistentOverviewType,
    ) {
        this.id = state.id;
        this.node = document.createElement('a');

        const icon: HTMLDivElement = document.createElement('div');
        const resource: HTMLDivElement = document.createElement('div');

        icon.textContent = state.icon;
        resource.textContent = state.name;

        this.units = document.createElement('div');
        this.units.classList.add('units-sold');
        this.units.setAttribute('data-tooltip-type', type.tooltipResourceIO);
        this.units.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, state.id]),
        );

        // this.value = document.createElement('div');
        this.price = new Ticker(Fortune.Bonus);
        this.price.outer.classList.add('price');
        this.price.outer.setAttribute('data-tooltip-type', type.tooltipExplainPrice);

        this.subtitle = document.createElement('div');
        this.subtitle.classList.add('subtitle');
        if (type.tooltipResourceOrigin !== undefined) {
            this.subtitle.setAttribute('data-tooltip-type', type.tooltipResourceOrigin);
        }

        this.node.appendChild(icon);
        this.node.appendChild(resource);
        this.node.appendChild(this.price.outer);
        this.node.appendChild(this.units);
        this.node.appendChild(this.subtitle);

        this.owner = owner;
        this.configure();
    }

    public update(state: ResourceSale, owner: GameID): void {
        if (this.owner !== owner) {
            this.owner = owner;
            this.configure();
        }

        UpdateBigInt(this.units, state.unitsSold);

        if (state.source !== undefined) {
            UpdateText(this.subtitle, state.source);
        } else {
            UpdateText(this.subtitle, '');
        }

        if (state.price !== undefined) {
            this.price.updatePriceChange(state.price.o, state.price.c, 2);
        }
    }

    private configure(): void {
        this.units.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.price.outer.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
        this.subtitle.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([this.owner, this.id]),
        );
    }
}
