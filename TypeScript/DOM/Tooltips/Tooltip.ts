import { TooltipBreakdown, TooltipInstructions, TooltipRenderer } from '../exports.js';

export class Tooltip<Type> {
    private flipped: boolean;
    private readonly tooltip: HTMLElement;
    public readonly node: HTMLDivElement;
    public source?: { arguments: any[], type: Type };

    constructor() {
        this.flipped = false;
        this.tooltip = document.createElement('aside');
        this.node = document.createElement('div');
        this.node.appendChild(this.tooltip);
        this.node.setAttribute('data-display', 'hidden');
    }

    public show(tooltip: TooltipInstructions | TooltipBreakdown | null): void {
        this.flipped = tooltip?.flipped ?? false;
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

        if (this.flipped === true) {
            // PREFER: Up and Left
            const offsetx: number = -15;
            const offsety: number = -25;

            // Apply offsets to shift position to Top/Left of cursor
            left += offsetx - bounds.width;
            top += offsety - bounds.height;

            // Check Left Edge: Flip back to Right if we clip the left edge
            if (event.clientX - bounds.width - margin + offsetx < frame.left) {
                left = event.clientX - frame.left;
            }

            // Check Top Edge: Flip back to Bottom if we clip the top edge
            if (event.clientY - bounds.height - margin + offsety < frame.top) {
                top = event.clientY - frame.top;
            }
        } else {
            // PREFER: Down and Right (Original Logic)

            // Check Right Edge: Flip to Left if we clip the right edge
            if (event.clientX + margin + bounds.width > footprintX) {
                left = event.clientX - frame.left - bounds.width;
            }

            // Check Bottom Edge: Flip to Top if we clip the bottom edge
            if (event.clientY + margin + bounds.height > footprintY) {
                top = event.clientY - frame.top - bounds.height;
            }
        }

        this.node.style.left = `${left}px`;
        this.node.style.top = `${top}px`;
    }

    public hide(): void {
        this.node.setAttribute('data-display', 'hidden');
        this.tooltip.replaceChildren();
    }
}
