import {
    Fortune,
    Ticker,
} from '../../DOM/exports.js';
import {
    FactoryWorkers,
    ProgressCell,
} from '../exports.js';

export class FactoryWorkersCell extends ProgressCell {
    public readonly wn: Ticker;

    constructor() {
        super();
        this.wn = new Ticker(Fortune.Bonus);
        this.summary.appendChild(this.wn.outer);
    }

    public update(workers: FactoryWorkers): void {
        this.set(100n * workers.count / workers.limit);
    }
}
