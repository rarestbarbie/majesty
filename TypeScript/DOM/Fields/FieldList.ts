import { FieldListItem } from '../exports.js';

export class FieldList<T extends FieldListItem> {
    readonly ul: HTMLUListElement;
    readonly items: T[];

    constructor() {
        this.ul = document.createElement('ul');
        this.items = [];
    }

    public update<U>(
        states: U[],
        create: () => T,
        update: (element: T, state: U) => void,
    ): void {
        if (this.items.length < states.length) {
            // add new entries
            for (let i: number = this.items.length; i < states.length; i++) {
                const element: T = create();
                this.ul.appendChild(element.li);
                this.items.push(element);
            }
        } else if (this.items.length > states.length) {
            // remove excess entries
            for (let i: number = states.length; i < this.items.length; i++) {
                this.items[i].li.remove();
            }
            this.items.length = states.length;
        }

        for (let i: number = 0; i < states.length; i++) {
            const item: T = this.items[i];
            update(item, states[i]);
        }
    }
}
