import { Swift } from "../../Swift.js";

export class ScreenContent {
    constructor() {
    }

    public async attach(root: HTMLElement | null, parameters: URLSearchParams): Promise<void> {
    }

    public detach(): void {
    }

    public async close(): Promise<void> {
        await Swift.closeScreen();
    }
}
