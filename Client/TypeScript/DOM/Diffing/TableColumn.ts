import {
    DiffableListElement,
    TableColumnMetadata,
    UpdateText
} from '../exports.js';

export class TableColumn implements DiffableListElement<number> {
    public readonly id: number;
    public readonly node: HTMLDivElement;

    constructor(id: number) {
        this.id = id;
        this.node = document.createElement('div');
    }

    public update<Stop>(
        column: TableColumnMetadata<Stop>,
        destination: (value: Stop) => string
    ): void {
        UpdateText(this.node, column.name);
        if (column.next !== undefined && column.previous !== undefined) {
            this.node.setAttribute('data-cl-destination', destination(column.next));
            this.node.setAttribute('data-cr-destination', destination(column.previous));
        }
    }
}
