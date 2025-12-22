import { Swift } from "../../Swift.js";

export class ScreenContent {
    constructor() {
    }

    public attach(root: HTMLElement): void {}
    public detach(): void {}

    public async open(parameters: URLSearchParams): Promise<void> {}
    public async close(): Promise<void> {
        await Swift.closeScreen();
    }
}
