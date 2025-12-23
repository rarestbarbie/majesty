import { ConsoleStdout } from '@bjorn3/browser_wasi_shim';
import {
    InfrastructureOverview,
    PersistentReport,
    PersistentOverviewType,
    PlanetOverview,
    PopulationOverview,
    ProductionOverview,
    ScreenContent,
    ScreenLayout,
    ScreenType,
    TradeOverview,
} from '../exports.js';

export class Screen {
    private dom?: {
        readonly element: HTMLDivElement;
        readonly heading: HTMLElement;
        readonly content: HTMLElement;
        readonly close: HTMLAnchorElement;

        readonly mousedown: (e: MouseEvent) => void;
        readonly mousemove: (e: MouseEvent) => void;
        readonly mouseup: () => void;
    };

    private isDragging: boolean = false;
    private offsetX: number = 0;
    private offsetY: number = 0;
    private lastMouseX: number = 0; // Track last mouse position for anchor updates
    private lastMouseY: number = 0;

    private state?: {
        content: ScreenContent,
        type: ScreenType,
    };

    constructor() {
    }

    public attach(parent: HTMLElement): void {
        // We have to hold references to the bound functions so we can remove them from the
        // document later. We must attach them to the document and not just the element
        // because we don’t want to “lose” the motion when the user drags the mouse outside the
        // element.
        this.dom = {
            element: document.createElement('div'),
            heading: document.createElement('h2'),
            content: document.createElement('article'),
            close: document.createElement('a'),

            mousedown: this.mousedown.bind(this),
            mousemove: this.mousemove.bind(this),
            mouseup: this.mouseup.bind(this),
        }

        this.dom.element.id = 'screen';
        this.dom.close.id = 'screen-close';
        this.dom.close.href = '#screen=_close';

        this.dom.element.appendChild(this.dom.heading);
        this.dom.element.appendChild(this.dom.content);
        this.dom.element.appendChild(this.dom.close);

        this.dom.content.addEventListener('mousedown', this.dom.mousedown);
        document.addEventListener('mousemove', this.dom.mousemove);
        document.addEventListener('mouseup', this.dom.mouseup);

        parent.appendChild(this.dom.element);
    }

    public detach(): void {
        if (!this.dom) {
            return;
        }

        this.state?.content.close();
        this.state?.content.detach();

        this.dom.content.removeEventListener('mousedown', this.dom.mousedown);
        document.removeEventListener('mousemove', this.dom.mousemove);
        document.removeEventListener('mouseup', this.dom.mouseup);

        this.dom.element.remove()
        this.dom = undefined;
    }

    public async close(): Promise<void> {
        if (!this.dom) {
            return;
        }

        this.dom.element.removeAttribute('data-screen');

        await this.state?.content.close();
        this.state?.content.detach();
        this.state = undefined
    }

    public async open(screen: ScreenType, parameters: URLSearchParams): Promise<void> {
        if (this.dom === undefined) {
            return;
        }

        if (this.state?.type === screen) {
            await this.state.content.open(parameters);
        } else {
            let uninitialized: ScreenContent;
            let layout: ScreenLayout;

            switch (screen) {
            case ScreenType.Planet:
                uninitialized = new PlanetOverview();
                layout = ScreenLayout.Planet;
                break;

            case ScreenType.Infrastructure:
                uninitialized = new InfrastructureOverview();
                layout = ScreenLayout.Explorer;
                break;

            case ScreenType.Production:
                uninitialized = new ProductionOverview();
                layout = ScreenLayout.Explorer;
                break;

            case ScreenType.Population:
                uninitialized = new PopulationOverview();
                layout = ScreenLayout.Explorer;
                break;

            case ScreenType.Budget:
                uninitialized = new ScreenContent();
                layout = ScreenLayout.Explorer;
                break;

            case ScreenType.Trade:
                uninitialized = new TradeOverview();
                layout = ScreenLayout.Explorer;
                break;
            }

            await this.state?.content.close();

            this.state?.content.detach();
            this.state = undefined;

            await uninitialized.open(parameters);

            this.dom.content.setAttribute('data-screen-layout', layout);
            this.dom.element.setAttribute('data-screen', screen);
            this.dom.heading.textContent = screen;

            this.state = { content: uninitialized, type: screen };
            this.state.content.attach(this.dom.content);
        }
    }

    public update(state: PersistentReport): void {
        if (this.state === undefined) {
            console.warn(`Unexpected update of type '${state.type}'!`);
            return;
        }

        switch (state.type) {
        case ScreenType.Infrastructure:
            if (this.state.content instanceof InfrastructureOverview) {
                this.state.content.update(state);
                return;
            } else {
                break;
            }
        case ScreenType.Production:
            if (this.state.content instanceof ProductionOverview) {
                this.state.content.update(state);
                return;
            } else {
                break;
            }
        case ScreenType.Population:
            if (this.state.content instanceof PopulationOverview) {
                this.state.content.update(state);
                return;
            } else {
                break;
            }
        case ScreenType.Trade:
            if (this.state.content instanceof TradeOverview) {
                this.state.content.update(state);
                return;
            } else {
                break;
            }
        }

        console.warn(
            `Unexpected update of type '${state.type}' for screen '${this.state.type}'!`
        );
    }

    /**
     * Handler for the start of a mouse drag
     * @param e - The mouse event
     */
    private mousedown(e: MouseEvent): void {
        if (!this.dom || e.button !== 0) {
            return;
        }

        this.isDragging = true;

        // Calculate the offset between mouse position and window position
        const rect: DOMRect = this.dom.element.getBoundingClientRect();
        this.offsetX = e.clientX - rect.left;
        this.offsetY = e.clientY - rect.top;

        // Store current mouse position
        this.lastMouseX = e.clientX;
        this.lastMouseY = e.clientY;
    }

    /**
     * Handler for mouse movement during drag
     * @param e - The mouse event
     */
    private mousemove(e: MouseEvent): void {
        if (!this.isDragging) return;

        // Store current mouse position for anchor adjustments
        this.lastMouseX = e.clientX;
        this.lastMouseY = e.clientY;

        // Calculate new position
        const newX: number = e.clientX - this.offsetX;
        const newY: number = e.clientY - this.offsetY;

        // Update window position with bounds checking
        this.updatePosition(newX, newY);
    }

    /**
     * Handler for the end of a drag operation (both mouse and touch)
     */
    private mouseup(): void {
        this.isDragging = false;
    }

    /**
     * Updates the window position ensuring it stays completely within the viewport.
     * When the window is larger than the viewport, prioritizes keeping the top-right corner visible.
     * Dynamically updates drag anchors when hitting viewport boundaries for responsive direction changes.
     *
     * @param newX - The new X position
     * @param newY - The new Y position
     */
    private updatePosition(newX: number, newY: number): void {
        if (!this.dom) {
            return;
        }
        // Get window dimensions
        const windowWidth: number = this.dom.element.getBoundingClientRect().width;
        const windowHeight: number = this.dom.element.getBoundingClientRect().height;

        // Get viewport dimensions
        const viewportWidth: number = document.documentElement.clientWidth;
        const viewportHeight: number = document.documentElement.clientHeight;

        // Store original calculated position before constraints
        const originalX: number = newX;
        const originalY: number = newY;

        // Handle cases where window is larger than viewport
        if (windowWidth > viewportWidth) {
            // Window is wider than viewport - prioritize showing the right side
            newX = viewportWidth - windowWidth;
        } else {
            // Normal case - keep window fully within horizontal bounds
            newX = Math.max(0, newX); // Left boundary
            newX = Math.min(viewportWidth - windowWidth, newX); // Right boundary
        }

        if (windowHeight > viewportHeight) {
            // Window is taller than viewport - prioritize showing the top
            newY = 0;
        } else {
            // Normal case - keep window fully within vertical bounds
            newY = Math.max(0, newY); // Top boundary
            newY = Math.min(viewportHeight - windowHeight, newY); // Bottom boundary
        }

        // Update window position
        this.dom.element.style.left = `${newX}px`;
        this.dom.element.style.top = `${newY}px`;

        // Check if position was constrained (hit viewport edge)
        if (originalX !== newX || originalY !== newY) {
            // Position was constrained, update drag anchor
            this.updateDragAnchor(newX, newY);
        }
    }

    /**
     * Updates the drag anchor (offset) when window position is constrained by viewport edges.
     * This ensures the window will immediately move when changing drag direction.
     *
     * @param constrainedX - The constrained X position of the window
     * @param constrainedY - The constrained Y position of the window
     */
    private updateDragAnchor(constrainedX: number, constrainedY: number): void {
        // Recalculate offset based on current mouse position and constrained window position
        this.offsetX = this.lastMouseX - constrainedX;
        this.offsetY = this.lastMouseY - constrainedY;
    }
}
