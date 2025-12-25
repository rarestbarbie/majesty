import { Identifiable, DiffableList, ManagedListElement } from '../exports.js';

export class ManagedList<T extends ManagedListElement<ID>, ID> extends DiffableList<T, ID> {
    public update<U extends Identifiable<ID>>(
        states: U[],
        create: (state: U) => T,
        update: (state: U, element: T) => void,
        selected: ID | undefined = undefined,
    ): void {
        super.updateObservable(
            states,
            create,
            update,
            (element: T) => element.detach(),
            selected
        );
    }

}
