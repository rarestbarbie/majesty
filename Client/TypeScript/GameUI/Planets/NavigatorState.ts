import { MinimapState, NavigatorTileState  } from "../exports.js";

export interface NavigatorState {
    readonly minimap?: MinimapState;
    readonly tile?: NavigatorTileState;
}
