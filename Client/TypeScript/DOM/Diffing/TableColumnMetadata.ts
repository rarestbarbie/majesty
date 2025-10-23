export interface TableColumnMetadata<Stop> {
    readonly id: number;

    readonly name: string;
    readonly next?: Stop;
    readonly previous?: Stop;
}
