import {
    DiffableListElement,
} from '../../DOM/exports.js';

export interface PieChartSector<ID> extends DiffableListElement<ID> {
    readonly id: ID;
    readonly node: SVGGElement;

    geometry?: SVGPathElement | SVGCircleElement;
}
