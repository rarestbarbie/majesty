import { GameID } from '../../GameEngine/exports.js';

export interface PopJobDescription {
    readonly id: GameID;
    readonly name: string;
    readonly size: bigint;
    readonly hire: bigint;
    readonly fire: bigint;
    readonly quit: bigint;
}
