import { Identifiable, DiffableListElement } from '../exports.js';

export abstract class DiffableList<T extends DiffableListElement<ID>, ID> extends Array<T> {
    readonly node: HTMLElement | SVGElement;

    constructor(node: HTMLElement | SVGElement) {
        super();
        this.node = node;
    }

    public allocateObservable(
        elements: ID[],
        create: (id: ID) => T,
        remove: (element: T) => void,
        selected: ID | undefined,
    ): void {
        const existing: Map<ID, T> = new Map();
        for (const element of this) {
            existing.set(element.id, element);
        }

        this.length = 0;

        const list: Element[] = [];
        for (const current of elements) {
            let element: T | undefined = existing.get(current);
            if (element) {
                existing.delete(element.id);
            } else {
                element = create(current);
            }

            const node: Element = element.node;

            if (current === selected) {
                node.classList.add("selected");
            } else {
                node.classList.remove("selected");
            }

            list.push(node);
            this.push(element);
        }

        // remove entries that are no longer in the list
        for (const element of existing.values()) {
            remove(element);
            element.node.remove();
        }

        // Skip nodes that have type `<header>`
        let next: Element | null = this.node.firstElementChild;
        while (next?.tagName.toLowerCase() === 'header') {
            next = next.nextElementSibling;
        }
        for (const node of list) {
            if (node !== next) {
                this.node.insertBefore(node, next);
            }
            next = node.nextElementSibling;
        }
    }

    public updateObservable<U extends Identifiable<ID>>(
        states: U[],
        create: (state: U) => T,
        update: (state: U, element: T) => void,
        remove: (element: T) => void,
        selected: ID | undefined,
    ): void {
        const existing: Map<ID, T> = new Map();
        for (const element of this) {
            existing.set(element.id, element);
        }

        this.length = 0;

        const list: Element[] = [];
        for (const current of states) {
            let element: T | undefined = existing.get(current.id);
            if (element) {
                existing.delete(element.id);
            } else {
                element = create(current);
            }

            update(current, element)

            const node: Element = element.node;

            if (current.id === selected) {
                node.classList.add("selected");
            } else {
                node.classList.remove("selected");
            }

            list.push(node);
            this.push(element);
        }

        // remove entries that are no longer in the list
        for (const element of existing.values()) {
            remove(element);
            element.node.remove();
        }

        // Skip nodes that have type `<header>`
        let next: Element | null = this.node.firstElementChild;
        while (next?.tagName.toLowerCase() === 'header') {
            next = next.nextElementSibling;
        }
        for (const node of list) {
            if (node !== next) {
                this.node.insertBefore(node, next);
            }
            next = node.nextElementSibling;
        }
    }
}
