import { DiffableListElement } from '../../DOM/exports.js';
import { ActionType, ScreenType } from '../exports.js';

export class PlanetMapLayerSelector implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLLIElement;
    private readonly link: HTMLAnchorElement;

    constructor(layer: string, screen?: ScreenType.Planet) {
        this.id = layer;

        this.link = document.createElement('a');
        if (screen === undefined) {
            this.link.href = `#action=${ActionType.Minimap}&layer=${layer}`;
        } else {
            this.link.href = `#screen=${screen}&details=${layer}`;
        }
        this.node = document.createElement('li');
        this.node.appendChild(this.link);
        this.node.setAttribute('data-map-layer', layer);
    }
}
