import { Color } from '../../GameEngine/exports.js';

export interface PieChartSector<ID> {
    readonly id: ID;
    readonly d?: string;
    readonly share: number;
    readonly value: { color: Color; name: string; };
}
