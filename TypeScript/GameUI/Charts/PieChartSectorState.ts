import { ColorReference } from '../../GameEngine/exports.js';

export interface PieChartSectorState<ID> {
    readonly id: ID;
    readonly d?: string;
    readonly share: number;
    readonly value: ColorReference;
}
