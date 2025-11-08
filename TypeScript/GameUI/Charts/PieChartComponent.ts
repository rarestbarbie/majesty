import {
    DiffableListElement,
} from '../../DOM/exports.js';

export interface PieChartComponent<ID> extends DiffableListElement<ID> {
    readonly id: ID;
    readonly node: SVGGElement;

    geometry?: SVGPathElement | SVGCircleElement;
}
