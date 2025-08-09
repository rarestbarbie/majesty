import { TooltipBuilderKey, TooltipPath } from './exports.js';

export class TooltipOwner {
    public readonly container: HTMLDivElement;

    constructor(path: TooltipPath, builder: TooltipBuilderKey) {
        this.container = document.createElement('div');
        this.container.setAttribute('data-tooltip-path', JSON.stringify(path));
        this.container.setAttribute('data-tooltip-type', builder);
    }
}
