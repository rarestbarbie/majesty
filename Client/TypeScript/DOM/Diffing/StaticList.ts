import { Identifiable, DiffableList, DiffableListElement } from '../exports.js';

export class StaticList<T extends DiffableListElement<ID>, ID> extends DiffableList<T, ID> {
    public update<U extends Identifiable<ID>>(
        states: U[],
        create: (state: U) => T,
        update: (state: U, element: T) => void,
        selected: ID | undefined = undefined,
    ): void {
        super.apply(
            states,
            create,
            update,
            (_: T) => {},
            selected
        );
    }

    public boxes(type: string): void {
        this.clear();
        this.node.dataset['boxes'] = type;
    }

    /// Reinitializes the list as a table with the given type and columns.
    /// All existing content will be removed.
    public table(type: string, columns: string[]): void {
        this.clear();

        const header: HTMLElement = document.createElement("header");
        for (const column of columns) {
            const heading: HTMLDivElement = document.createElement("div");
            heading.textContent = column;
            header.appendChild(heading);
        }
        this.node.appendChild(header);
        this.node.dataset['table'] = type;
    }

    public clear(): void {
        this.node.replaceChildren();
        this.length = 0;
    }
}
