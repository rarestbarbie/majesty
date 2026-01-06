import { DiffableListElement } from '../../DOM/exports.js';
import { PlanetFilterLabel, ScreenType } from '../exports.js';

export class PlanetFilter implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLLIElement;

    private readonly link: HTMLAnchorElement;
    // TODO: add planet sprite
    private readonly icon: HTMLSpanElement;
    private readonly name: HTMLSpanElement;

    constructor(label: PlanetFilterLabel, screen: ScreenType.Planet) {
        this.id = label.id;
        this.node = document.createElement('li');
        this.link = document.createElement('a');
        this.icon = document.createElement('span');
        this.name = document.createElement('span');

        this.name.textContent = label.name;

        this.link.href = `#screen=${screen}&filter=${label.id}`;
        this.link.appendChild(this.icon);
        this.link.appendChild(this.name);
        this.node.appendChild(this.link);
    }
}
