import { PlayerEvent } from './exports.js';

export interface PlayerMessage {
    readonly from: string;
    readonly type: PlayerEvent;
    readonly seq: string;
}
