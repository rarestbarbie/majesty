import {
    Fortune,
    Ticker,
} from '../../DOM/exports.js';
import {
    FactoryWorkers,
    ProgressCell,
} from '../exports.js';

export class FactoryWorkersCell extends ProgressCell {
    public readonly wage: Ticker;

    constructor() {
        super();
        this.wage = new Ticker(Fortune.Bonus);
        this.summary.appendChild(this.wage.outer);
    }

    public update(workers: FactoryWorkers | undefined): void {
        if (workers === undefined) {
            this.set(0n);
        } else {
            this.set(100n * workers.count / workers.limit);
        }
    }
}
