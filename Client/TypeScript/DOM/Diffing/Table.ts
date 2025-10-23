import {
    StaticList,
    DiffableListElement,
    TableColumn,
    TableColumnMetadata
} from '../exports.js';

export class Table<T extends DiffableListElement<ID>, ID> extends StaticList<T, ID> {
    readonly header: StaticList<TableColumn, number>;

    constructor(type: string) {
        super(document.createElement('div'));
        this.header = new StaticList<TableColumn, number>(document.createElement('header'));
        this.node.appendChild(this.header.node);
        this.node.setAttribute('data-table', type);
    }

    public updateHeader(columns: TableColumnMetadata<any>[]): void {
        this.header.update(
            columns,
            (column: TableColumnMetadata<any>) => new TableColumn(column.id),
            (column: TableColumnMetadata<any>, element: TableColumn) => element.update(column),
        );
    }
}
