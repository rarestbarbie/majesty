import {
    DiffableListElement,
    StaticList
} from '../exports.js';

export class FilterList<T extends DiffableListElement<ID>, ID> extends StaticList<T, ID> {
    public readonly label: HTMLLabelElement

    constructor(label: string) {
        super(document.createElement('ul'));

        const icon: HTMLSpanElement = document.createElement('span');
        icon.textContent = label;

        this.label = document.createElement('label');
        this.label.appendChild(icon);
    }
}
