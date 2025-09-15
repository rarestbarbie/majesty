import * as GameEngine from '../../GameEngine/exports.js';
import { DiffableListElement } from '../../DOM/exports.js';
import { MinimapLayer, PlanetMapTileState } from '../exports.js';

export class HexGridCellBackground implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: SVGGElement;
    public readonly path: SVGPathElement;
    public readonly twin?: SVGPathElement;

    constructor(tile: PlanetMapTileState) {
        this.id = tile.id;
        this.path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        this.node = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        this.node.appendChild(this.path);
        if (tile.d1) {
            this.twin = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            this.node.appendChild(this.twin);
        }
    }

    public update(tile: PlanetMapTileState): void {
        if (tile.color) {
            this.node.setAttribute('fill', GameEngine.hex(tile.color));
        } else {
            this.node.removeAttribute('fill');
        }

        if (tile.x != undefined) {
            this.node.style.setProperty('--value-x', tile.x.toString());
        }
        if (tile.y != undefined) {
            this.node.style.setProperty('--value-y', tile.y.toString());
        }
        if (tile.z != undefined) {
            this.node.style.setProperty('--value-z', tile.z.toString());
        }
    }
}
