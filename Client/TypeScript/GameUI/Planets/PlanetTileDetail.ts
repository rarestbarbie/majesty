import { Navigator } from '../exports.js';

export class PlanetTileDetail {
    readonly node: HTMLDivElement;
    private readonly header: HTMLElement;
    private readonly detail: HTMLDivElement;

    constructor() {
        this.detail = document.createElement('div');
        this.header = document.createElement('header');

        this.node = document.createElement('div');
        this.node.id = 'tile';
        this.node.appendChild(this.header);
        this.node.appendChild(this.detail);

        this.node.style.display = 'none';
    }

    public update(navigator: Navigator): void {
        if (!navigator.planet || !navigator.tile) {
            this.node.style.display = 'none';
            return;
        } else {
            this.node.style.display = 'block';
        }

        const name: string = navigator.tile.name ?? navigator.tile.terrain;
        this.header.innerText = `${name} (${navigator.planet.name})`;
    }
}
