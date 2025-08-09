export class ProgressCell {
    public readonly node: HTMLDivElement;
    public readonly summary: HTMLSpanElement;

    constructor() {
        this.summary = document.createElement('span');
        this.node = document.createElement('div');
        this.node.appendChild(this.summary);
        this.node.setAttribute('data-cell', 'progress');
    }

    public set(progress: number | bigint): void {
        this.node.style.setProperty('--progress', `${progress}%`);
    }
}
