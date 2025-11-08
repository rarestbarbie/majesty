import { TooltipBreakdown, TooltipInstructions, TooltipRenderer } from '../exports.js';

export class Tooltip<Type> {
    private readonly tooltip: HTMLElement;
    public readonly node: HTMLDivElement;
    public source?: { arguments: any[], type: Type };

    constructor() {
        this.tooltip = document.createElement('aside');
        this.node = document.createElement('div');
        this.node.appendChild(this.tooltip);
        this.node.setAttribute('data-display', 'hidden');
    }

    public show(tooltip: TooltipInstructions | TooltipBreakdown | null): void {
        const list: HTMLUListElement[] = tooltip === null
            ? []
            : TooltipRenderer.render(tooltip);
        this.tooltip.replaceChildren(...list);
        this.tooltip.className = tooltip?.display ?? '';
        this.node.setAttribute('data-display', 'floating');
    }

    public move(event: MouseEvent, frame: DOMRect) {
        const bounds: DOMRect = this.tooltip.getBoundingClientRect();
        const footprintX: number = frame.right - frame.left;
        const footprintY: number = frame.bottom - frame.top;
        const margin: number = 20;

        let left: number = event.clientX - frame.left;
        let top: number = event.clientY - frame.top;

        if (event.clientX + margin + bounds.width > footprintX) {
            left = event.clientX - frame.left - bounds.width;
        }

        if (event.clientY + margin + bounds.height > footprintY) {
            top = event.clientY - frame.top - bounds.height;
        }

        this.node.style.left = `${left}px`;
        this.node.style.top = `${top}px`;
    }

    public hide(): void {
        this.node.setAttribute('data-display', 'hidden');
        this.tooltip.replaceChildren();
    }
}
