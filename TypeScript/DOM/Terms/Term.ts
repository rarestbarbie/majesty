
import {
    DiffableListElement,
    TooltipInstruction,
    TooltipInstructionType,
    Ticker,
    Count,
    Factor,
    TermState,
    UpdateText,
} from '../exports.js';

export class Term implements DiffableListElement<string> {
    public readonly id: string;
    public readonly node: HTMLLIElement;
    private readonly label: HTMLSpanElement;

    private details: Ticker | Factor | Count;

    constructor(term: TermState) {
        this.id = term.id;

        this.label = document.createElement('span');
        this.label.setAttribute('data-term-id', term.id);
        this.node = document.createElement('li');
        this.node.appendChild(this.label);

        switch (term.details.type) {
            case TooltipInstructionType.Ticker: {
                this.details = new Ticker(term.details.fortune);
                break;
            }
            case TooltipInstructionType.Factor: {
                this.details = new Factor();
                break;
            }
            case TooltipInstructionType.Count: {
                this.details = new Count();
                break;
            }
            default: {
                throw new Error(`Invalid details type for Term: ${term.details.type}`);
            }
        }

        this.node.appendChild(this.details.outer);
    }

    public update(term: TermState, tooltipArguments?: any[]): void {
        switch (term.details.type) {
            case TooltipInstructionType.Ticker: {
                UpdateText(this.label, term.details.label);
                (this.details as Ticker).update(term.details);
                break;
            }
            case TooltipInstructionType.Factor: {
                UpdateText(this.label, term.details.label);
                (this.details as Factor).update(term.details);
                break;
            }
            case TooltipInstructionType.Count: {
                UpdateText(this.label, term.details.label);
                (this.details as Count).update(term.details);
                break;
            }
            default: {
                throw new Error(`Invalid details type for Term: ${term.details.type}`);
            }
        }

        if (term.tooltip !== undefined) {
            this.details.outer.setAttribute('data-tooltip-type', term.tooltip);

            if (tooltipArguments !== undefined) {
                this.details.outer.setAttribute(
                    'data-tooltip-arguments',
                    JSON.stringify(tooltipArguments),
                );
            }
        }
    }
}
