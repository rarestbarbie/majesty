import { DiffableListElement } from '../../DOM/exports.js';
import { PlanetMapTileState, TooltipType } from '../exports.js';

export class HexGridCell implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: SVGAElement;
    public readonly path: SVGPathElement;
    public readonly twin?: SVGPathElement;

    constructor(tile: PlanetMapTileState) {
        this.id = tile.id;
        this.path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        this.node = document.createElementNS('http://www.w3.org/2000/svg', 'a');
        this.node.appendChild(this.path);
        if (tile.d1) {
            this.twin = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            this.node.appendChild(this.twin);
        }
    }
}
