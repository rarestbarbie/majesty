import {
    DiffableListElement,
} from '../../DOM/exports.js';

export interface TimeSeriesChannel<ID> extends DiffableListElement<ID> {
    readonly id: ID;
    readonly node: SVGPathElement;
}
