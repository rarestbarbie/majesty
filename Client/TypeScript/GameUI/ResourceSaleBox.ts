import {
    DiffableListElement,
    Fortune,
    Ticker,
    UpdateBigInt,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import { Resource, ResourceSale, TooltipType } from './exports.js';

export class ResourceSaleBox implements DiffableListElement<Resource> {
    public readonly id: Resource;
    public readonly node: HTMLAnchorElement;

    private readonly units: HTMLElement;
    private readonly value: HTMLElement;
    private readonly price: Ticker;

    constructor(
        sale: ResourceSale,
        owner: GameID,
        supply: TooltipType,
        explainPrice: TooltipType,
    ) {
        this.id = sale.id;
        this.node = document.createElement('a');

        const icon: HTMLDivElement = document.createElement('div');
        const resource: HTMLDivElement = document.createElement('div');

        icon.textContent = sale.icon;
        resource.textContent = sale.name;

        this.units = document.createElement('div');
        this.units.setAttribute('data-tooltip-type', supply);
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
        proceeds.setAttribute('data-tooltip-type', explainPrice);
        proceeds.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, null, sale.id]),
        );

        this.node.appendChild(icon);
        this.node.appendChild(resource);
        this.node.appendChild(this.units);
        this.node.appendChild(proceeds);
    }

    public update(sale: ResourceSale): void {
        UpdateBigInt(this.units, sale.unitsSold);
        UpdateBigInt(this.value, sale.valueSold);

        if (sale.priceAtMarket !== undefined) {
            this.price.updatePriceChange(sale.priceAtMarket.o, sale.priceAtMarket.c, 2);
        } else if (sale.price !== undefined) {
            this.price.updateBigIntChange(sale.price.o, sale.price.c);
        }
    }
}
