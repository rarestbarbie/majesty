import { ConditionListItem, FieldListItem } from '../exports.js';

export class ConditionLine implements FieldListItem {
    readonly li: HTMLLIElement;
    private readonly effect: HTMLSpanElement;
    private readonly description: HTMLSpanElement;

    constructor() {
        this.li = document.createElement('li');
        this.effect = document.createElement('span');
        this.description = document.createElement('span');

        this.li.appendChild(this.effect);
        this.li.appendChild(this.description);
    }

    public update(item: ConditionListItem): void {
        const description: string = item.description;
        const colon: number = description.indexOf(':');

        let magnitude: string | undefined;

        // A factor must start with a sign or a digit, and contain a colon.
        const first: string = description[0];
        if (colon > 0 && (first == '−' || first == '+' || (first >= '0' && first <= '9'))) {
            magnitude = description.substring(0, colon);
            this.effect.classList.add('effect');
            this.description.innerHTML = description.substring(colon + 1).trim();
        } else {
            this.effect.classList.remove('effect');
            this.description.innerHTML = description;
        }

        if (magnitude) {
            if (magnitude.startsWith('+')) {
                this.effect.dataset['sign'] = 'pos';
            } else if (magnitude.startsWith('−')) {
                this.effect.dataset['sign'] = 'neg';
            } else {
                delete this.effect.dataset['sign'];
            }
            this.effect.textContent = magnitude;
        } else {
            delete this.effect.dataset['sign'];
            this.effect.textContent = '';
        }

        this.li.style.setProperty('--indent', `${item.indent}`);

        if (item.fulfilled === true) {
            this.li.dataset['condition'] = 'true';
        } else if (item.fulfilled === false) {
            this.li.dataset['condition'] = 'false';
        }

        if (item.highlight) {
            this.li.classList.add('highlight');
        } else {
            this.li.classList.remove('highlight');
        }
    }
}
