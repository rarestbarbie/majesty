import { DiffableListElement } from '../../DOM/exports.js';
import { PlanetGridCell } from '../exports.js';

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
}
