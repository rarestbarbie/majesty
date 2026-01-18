export * from './Color.js';
export * from './ColorReference.js';
export * from './GameDate.js';
export * from './GameDateComponents.js';
export * from './GameID.js';

import { Color } from './Color.js';
import { ColorReference } from './ColorReference.js';

export function hex(color: Color): string {
    const hexColor = color.toString(16).padStart(6, '0');
    return `#${hexColor}`;
}

export function UpdateColorReference(node: HTMLElement | SVGElement, label: ColorReference) {
    if (label.color !== undefined) {
        node.style.setProperty('--fill', hex(label.color));
    }
    if (label.style !== undefined) {
        node.setAttribute('class', label.style);
    }
}
