import { DiffableListElement } from '../exports.js';

export interface ManagedListElement<ID> extends DiffableListElement<ID> {
    detach(): void;
}
