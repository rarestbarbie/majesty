import { DiffableListElement } from '../../DOM/exports.js';
import { ScreenType } from "../exports.js";

export class GenderFilter implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLLIElement;
    private readonly link: HTMLAnchorElement;

    constructor(code: string, screen: ScreenType = ScreenType.Population) {
        this.id = code;
        this.node = document.createElement('li');
        this.link = document.createElement('a');

        this.link.href = `#screen=${screen}&filter=${code}`;
        this.link.setAttribute('data-gender-icon', code);
        this.node.appendChild(this.link);
    }

    public update(code: string): void {
    }
}
