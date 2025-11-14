import {
    FieldList,
    ConditionLine,
    ConditionListItem,
    TooltipBreakdown,
    TooltipInstruction,
    TooltipInstructions,
    TooltipInstructionType,
    UpdateText,
} from '../exports.js';

export class TooltipRenderer {
    private static li(label: string): HTMLLIElement {
        const li: HTMLLIElement = document.createElement('li');
        const span: HTMLSpanElement = document.createElement('span');
        span.className = 'label';
        span.textContent = label;
        li.appendChild(span);
        return li;
    }

    public static render(tooltip: TooltipInstructions | TooltipBreakdown): HTMLUListElement[] {
        if ('conditions' in tooltip) {
            const lists: HTMLUListElement[] = [];
            for (const conditions of tooltip.conditions) {
                const fields: FieldList<ConditionLine> = new FieldList<ConditionLine>();
                fields.ul.classList.add('conditions');
                fields.update(
                    conditions,
                    () => new ConditionLine(),
                    (line: ConditionLine, state: ConditionListItem) => line.update(state)
                );
                lists.push(fields.ul);
            }
            return lists;
        }

        const list: HTMLUListElement = document.createElement('ul');
        list.className = 'factors';

        for (const instruction of tooltip.instructions) {
            list.appendChild(this.renderItem(instruction));
        }

        return [list];
    }

    private static renderItem(instruction: TooltipInstruction): HTMLLIElement {
        let li: HTMLLIElement;

        switch (instruction.type) {
            case TooltipInstructionType.Header: {
                li = document.createElement('li');
                const p: HTMLParagraphElement = document.createElement('p');
                p.innerHTML = instruction.html;
                li.appendChild(p);
                li.classList.add('header');
                break;
            }

            case TooltipInstructionType.Ticker: {
                li = this.li(instruction.label);
                const ticker: HTMLSpanElement = document.createElement('span');
                const value: HTMLSpanElement = document.createElement('span');
                const delta: HTMLSpanElement = document.createElement('span');

                value.innerText = instruction.value;
                delta.innerText = instruction.delta;
                delta.dataset['sign'] = instruction.sign ?? 'zero';

                ticker.dataset['ticker'] = instruction.fortune;
                ticker.appendChild(value);
                ticker.appendChild(delta);
                li.appendChild(ticker);
                break;
            }

            case TooltipInstructionType.Factor: {
                li = this.li(instruction.label);
                const value: HTMLSpanElement = document.createElement('span');

                value.dataset['sign'] = instruction.sign ?? 'zero';
                value.dataset['factor'] = instruction.fortune;
                value.innerText = instruction.value;

                li.appendChild(value);
                break;
            }

            case TooltipInstructionType.Count: {
                li = this.li(instruction.label);
                const count: HTMLSpanElement = document.createElement('span');
                const value: HTMLSpanElement = document.createElement('span');
                const limit: HTMLSpanElement = document.createElement('span');

                value.innerText = instruction.value;
                value.dataset['sign'] = instruction.sign ?? 'zero';
                limit.innerText = instruction.limit;

                count.dataset['count'] = instruction.fortune;
                count.appendChild(value);
                count.appendChild(limit);
                li.appendChild(count);
                break;
            }
        }

        if (instruction.indent !== undefined) {
            const indent: string = `${instruction.indent}`;
            li.style.setProperty('--indent', indent);
            li.setAttribute('data-indent', indent);
        }

        return li;
    }
}
