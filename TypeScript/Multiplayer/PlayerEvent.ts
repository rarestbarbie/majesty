import { PlayerEventID } from './exports.js';

export type PlayerEvent = PlayerTick
    | PlayerFaster
    | PlayerSlower
    | PlayerPause;

export interface PlayerTick {
    readonly id: PlayerEventID.Tick;
}
export interface PlayerFaster {
    readonly id: PlayerEventID.Faster;
}
export interface PlayerSlower {
    readonly id: PlayerEventID.Slower;
}
export interface PlayerPause {
    readonly id: PlayerEventID.Pause;
}
