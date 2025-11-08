export * from './Color.js';
export * from './GameDate.js';
export * from './GameDateComponents.js';
export * from './GameID.js';

import { Color } from './Color.js';

export function hex(color: Color): string {
    const hexColor = color.toString(16).padStart(6, '0');
    return `#${hexColor}`;
}
