import {
    DiffableListElement,
    UpdateBigInt,
} from '../DOM/exports.js';
import { Resource, ResourceSale } from './exports.js';

export class ResourceSaleBox implements DiffableListElement<Resource> {
    public readonly id: Resource;
    public readonly node: HTMLAnchorElement;

    private readonly unitsProduced: HTMLElement;
    private readonly unitsLeftover: HTMLElement;
    private readonly valueSold: HTMLElement;

    constructor(sale: ResourceSale) {
        this.id = sale.id;
        this.node = document.createElement('a');

        const icon: HTMLDivElement = document.createElement('div');
        const resource: HTMLDivElement = document.createElement('div');

        this.unitsProduced = document.createElement('div');
        this.unitsLeftover = document.createElement('div');
        this.valueSold = document.createElement('div');

        icon.textContent = sale.icon;
        resource.textContent = sale.name;

        this.node.appendChild(icon);
        this.node.appendChild(resource);
        this.node.appendChild(this.unitsProduced);
        this.node.appendChild(this.unitsLeftover);
        this.node.appendChild(this.valueSold);
    }

    public update(sale: ResourceSale): void {
        UpdateBigInt(this.unitsProduced, sale.unitsProduced);
        UpdateBigInt(this.unitsLeftover, sale.unitsProduced - sale.unitsSold);
        UpdateBigInt(this.valueSold, sale.valueSold);
    }
}
