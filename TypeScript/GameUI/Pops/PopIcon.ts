import {
    GameID
} from '../../GameEngine/exports.js';
import {
    TooltipType
} from '../exports.js';

export class PopIcon {
    readonly occupation: HTMLDivElement;
    readonly gender: HTMLDivElement;

    constructor() {
        const occupation: HTMLSpanElement = document.createElement('span');
        this.occupation = document.createElement('div');
        this.occupation.appendChild(occupation);

        this.occupation.setAttribute('data-tooltip-type', TooltipType.PopType);

        this.gender = document.createElement('div');
    }

    public set(
        pop: {id: GameID, occupation: string, gender: string, cis: boolean} | null
    ): void {
        if (pop !== null) {
            this.occupation.setAttribute('data-pop-type', pop.occupation);
            this.occupation.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));
            this.gender.setAttribute('data-gender', pop.gender);
            this.gender.setAttribute('data-gender-type', pop.cis ? 'cis' : 'trans');
        } else {
            this.occupation.removeAttribute('data-pop-type');
            this.occupation.removeAttribute('data-tooltip-arguments');
            this.gender.removeAttribute('data-gender');
            this.gender.removeAttribute('data-gender-type');
        }
    }
}
