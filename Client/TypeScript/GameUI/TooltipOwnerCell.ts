import { TooltipBuilderKey, TooltipOwner, TooltipPath } from './exports.js';

export class TooltipOwnerCell extends TooltipOwner {
    public readonly summary: HTMLSpanElement;

    constructor(path: TooltipPath, builder: TooltipBuilderKey) {
        super(path, builder);
        this.summary = document.createElement('span');
        this.container.appendChild(this.summary);
    }
}
