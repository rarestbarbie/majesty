import {
    DiffableListElement,
    UpdateBigInt,
} from '../DOM/exports.js';
import { Resource, ResourceSale } from './exports.js';

export class ResourceSaleBox implements DiffableListElement<Resource> {
    public readonly id: Resource;
    public readonly node: HTMLAnchorElement;

    private readonly quantity: HTMLElement;
    private readonly leftover: HTMLElement;
    private readonly proceeds: HTMLElement;

    constructor(sale: ResourceSale) {
        this.id = sale.id;
        this.node = document.createElement('a');

        const icon: HTMLDivElement = document.createElement('div');
        const resource: HTMLDivElement = document.createElement('div');

        this.quantity = document.createElement('div');
        this.leftover = document.createElement('div');
        this.proceeds = document.createElement('div');

        icon.textContent = sale.icon;
        resource.textContent = sale.name;

        this.node.appendChild(icon);
        this.node.appendChild(resource);
        this.node.appendChild(this.quantity);
        this.node.appendChild(this.leftover);
        this.node.appendChild(this.proceeds);
    }

    public update(sale: ResourceSale): void {
        UpdateBigInt(this.quantity, sale.quantity);
        UpdateBigInt(this.leftover, sale.leftover);
        UpdateBigInt(this.proceeds, sale.proceeds);

        // if (sale.leftover != 0n) {
        //     this.leftover.classList.add('shortage');
        // } else {
        //     this.leftover.classList.remove('shortage');
        // }
    }
}
