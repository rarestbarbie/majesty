import { Swift } from "../../Swift.js";

export class ScreenContent {
    constructor() {
    }

    public attach(root: HTMLElement | null, parameters: URLSearchParams): void {
    }

    public detach(): void {
    }

    public close(): void {
        Swift.closeScreen();
    }
}
