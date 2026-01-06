import { DiffableListElement } from '../DOM/exports.js';
import { LegalEntityFilterLabel, ScreenType } from './exports.js';

export class LegalEntityFilter implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLLIElement;

    private readonly link: HTMLAnchorElement;
    private readonly name: HTMLSpanElement;

    constructor(label: LegalEntityFilterLabel, screen: ScreenType) {
        this.id = label.id;
        this.node = document.createElement('li');
        this.link = document.createElement('a');
        this.name = document.createElement('span');

        this.name.textContent = label.name;

        this.link.href = `#screen=${screen}&filter=${label.id}`;
        this.link.appendChild(this.name);
        this.node.appendChild(this.link);
    }
}
