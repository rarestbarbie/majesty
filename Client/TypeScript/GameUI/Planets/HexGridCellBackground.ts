import * as GameEngine from '../../GameEngine/exports.js';
import { DiffableListElement } from '../../DOM/exports.js';
import { MinimapLayer, PlanetGridCell } from '../exports.js';

export class HexGridCellBackground implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: SVGGElement;
    public readonly path: SVGPathElement;
    public readonly twin?: SVGPathElement;

    constructor(cell: PlanetGridCell) {
        this.id = cell.id;
        this.path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        this.node = document.createElementNS('http://www.w3.org/2000/svg', 'g');
        this.node.appendChild(this.path);
        if (cell.d1) {
            this.twin = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            this.node.appendChild(this.twin);
        }
    }

    public update(cell: PlanetGridCell): void {
        if (cell.color) {
            this.node.setAttribute('fill', GameEngine.hex(cell.color));
        } else {
            this.node.removeAttribute('fill');
        }

        if (cell.x != undefined) {
            this.node.style.setProperty('--value-x', cell.x.toString());
        }
        if (cell.y != undefined) {
            this.node.style.setProperty('--value-y', cell.y.toString());
        }
        if (cell.z != undefined) {
            this.node.style.setProperty('--value-z', cell.z.toString());
        }
    }
}
