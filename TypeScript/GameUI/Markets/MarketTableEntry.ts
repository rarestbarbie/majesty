export interface MarketTableEntry {
    readonly id: string;
    readonly name: string;
    readonly open: number;
    readonly close: number;
    readonly volume_y: number;
    readonly volume_z: number;
    readonly velocity_y: number;
    readonly velocity_z: number;
}
