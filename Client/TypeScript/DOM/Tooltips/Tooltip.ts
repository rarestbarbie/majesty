import { TooltipBreakdown, TooltipInstructions, TooltipRenderer } from '../exports.js';

export class Tooltip<Type> {
    private readonly tooltip: HTMLElement;
    public readonly node: HTMLDivElement;
    public source?: { arguments: any[], type: Type };

    constructor() {
        this.tooltip = document.createElement('aside');
        this.node = document.createElement('div');
        this.node.appendChild(this.tooltip);
        this.node.setAttribute('data-tooltip', 'hidden');
    }

    public show(tooltip: TooltipInstructions | TooltipBreakdown | null): void {
        const list: HTMLUListElement[] = tooltip === null
            ? []
            : TooltipRenderer.render(tooltip);
        this.tooltip.replaceChildren(...list);
        this.tooltip.className = tooltip?.display ?? '';
        this.node.setAttribute('data-tooltip', 'floating');
    }

    public move(event: MouseEvent, frame: DOMRect) {
        this.node.style.left = `${event.clientX - frame.left}px`;
        this.node.style.top = `${event.clientY - frame.top}px`;
    }

    public hide(): void {
        this.node.setAttribute('data-tooltip', 'hidden');
        this.tooltip.replaceChildren();
    }
}
