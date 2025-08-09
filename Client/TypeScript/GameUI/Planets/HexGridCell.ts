import { DiffableListElement } from '../../DOM/exports.js';
import { PlanetGridCell, TooltipBuilderKey } from '../exports.js';

export class HexGridCell implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: SVGAElement;
    public readonly path: SVGPathElement;

    constructor(cell: PlanetGridCell, path: any[]) {
        this.id = cell.id;
        this.path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        this.node = document.createElementNS('http://www.w3.org/2000/svg', 'a');
        this.node.setAttribute('data-tooltip-type', TooltipBuilderKey.PlanetCell);
        this.node.setAttribute('data-tooltip-arguments', JSON.stringify(path));
        this.node.appendChild(this.path);
    }
}
