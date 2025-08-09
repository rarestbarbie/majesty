import { DiffableListElement } from '../../DOM/exports.js';
import { PlanetGridCell } from '../exports.js';

export class HexGridCellBackground implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: SVGPathElement;

    constructor(cell: PlanetGridCell) {
        this.id = cell.id;
        this.node = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    }
}
