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

    public update(column: TableColumnMetadata<any>): void {
        UpdateText(this.node, column.name);
        if (column.next !== undefined && column.previous !== undefined) {
            this.node.setAttribute('data-cc-prev', `${column.previous}`);
            this.node.setAttribute('data-cc-next', `${column.next}`);
        }
    }
}
