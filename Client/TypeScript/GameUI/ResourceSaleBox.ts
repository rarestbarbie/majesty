import {
    DiffableListElement,
    Fortune,
    Ticker,
    UpdateBigInt,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import { PersistentOverviewType, ResourceSale, TooltipType } from './exports.js';

export class ResourceSaleBox implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLAnchorElement;

    private readonly units: HTMLElement;
    private readonly value: HTMLElement;
    private readonly price: Ticker;

    constructor(
        sale: ResourceSale,
        owner: GameID,
        type: PersistentOverviewType,
    ) {
        this.id = sale.id;
        this.node = document.createElement('a');

        const icon: HTMLDivElement = document.createElement('div');
        const resource: HTMLDivElement = document.createElement('div');

        icon.textContent = sale.icon;
        resource.textContent = sale.name;

        this.units = document.createElement('div');
        this.units.setAttribute('data-tooltip-type', type.tooltipResourceIO);
        this.units.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, sale.id]),
        );

        const proceeds: HTMLDivElement = document.createElement('div');

        this.value = document.createElement('div');
        this.price = new Ticker(Fortune.Bonus);

        proceeds.appendChild(this.value);
        proceeds.appendChild(this.price.outer);
        proceeds.classList.add('proceeds');
        proceeds.setAttribute('data-tooltip-type', type.tooltipExplainPrice);
        proceeds.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, sale.id]),
        );

        this.node.appendChild(icon);
        this.node.appendChild(resource);
        this.node.appendChild(this.units);
        this.node.appendChild(proceeds);

        if (sale.source !== undefined) {
            const subtitle: HTMLDivElement = document.createElement('div');
            subtitle.classList.add('subtitle');
            subtitle.textContent = sale.source;

            if (type.tooltipResourceOrigin !== undefined) {
                subtitle.setAttribute('data-tooltip-type', type.tooltipResourceOrigin);
                subtitle.setAttribute(
                    'data-tooltip-arguments',
                    JSON.stringify([owner, sale.id]),
                );
            }

            this.node.appendChild(subtitle);
        }
    }

    public update(sale: ResourceSale): void {
        UpdateBigInt(this.units, sale.unitsSold);
        UpdateBigInt(this.value, sale.valueSold);

        if (sale.price !== undefined) {
            this.price.updatePriceChange(sale.price.o, sale.price.c, 2);
        }
    }
}
