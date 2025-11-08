import {
    FilterList,
} from '../exports.js';

export class FilterTabs {
    private static instance: number = 0;

    public readonly node: HTMLDivElement;
    public readonly tabs: HTMLInputElement[];

    constructor(lists: FilterList<any, any>[]) {
        this.node = document.createElement('div');
        this.node.classList.add('tabs');
        this.tabs = [];

        const i: number = FilterTabs.instance++;
        let j: number = 0;

        for (const list of lists) {
            const input: HTMLInputElement = document.createElement('input');

            this.tabs.push(input);

            const container: HTMLDivElement = document.createElement('div');
            const content: HTMLDivElement = document.createElement('div');

            const id: string = `filterlist-${i}-${j}`;
            input.type = 'radio';
            input.id = id;
            input.name = `filterlist-${i}`;

            list.label.htmlFor = id;

            content.classList.add('tabcontent');
            content.appendChild(list.node);

            container.appendChild(input);
            container.appendChild(list.label);
            container.appendChild(content);

            this.node.appendChild(container);

            j += 1;
        }
    }
}
