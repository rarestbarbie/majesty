import {
    DiffableListElement,
    UpdateBigInt,
    UpdateText,
    UpdatePrice,
    Ticker,
    Fortune,
} from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    CellStyle,
    FactoryTableEntry,
    FactoryWorkersCell,
    ProgressCell,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class FactoryTableRow implements DiffableListElement<GameID> {
    public readonly id: GameID;
    public readonly node: HTMLAnchorElement;

    private readonly type: ProgressCell;
    private readonly location: HTMLElement;
    private readonly workers: FactoryWorkersCell;
    private readonly clerks: FactoryWorkersCell;
    private readonly px: Ticker;
    private readonly fi: HTMLElement;

    public static get columns(): string[] {
        return [
            "Type",
            "Location",
            "Workers",
            "Clerks",
            "Share price",
            "Needs",
        ];
    }

    constructor(factory: FactoryTableEntry) {
        this.id = factory.id;
        this.node = document.createElement('a');

        this.type = new ProgressCell();
        this.type.node.setAttribute('data-tooltip-type', TooltipType.FactorySize);
        this.type.node.setAttribute('data-tooltip-arguments', JSON.stringify([factory.id]));
        this.location = document.createElement('div');

        this.workers = new FactoryWorkersCell();
        this.workers.node.setAttribute('data-tooltip-type', TooltipType.FactoryWorkers);
        this.workers.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([factory.id, 'Worker'])
        );
        this.clerks = new FactoryWorkersCell();
        this.clerks.node.setAttribute('data-tooltip-type', TooltipType.FactoryWorkers);
        this.clerks.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([factory.id, 'Clerk'])
        );

        this.px = new Ticker(Fortune.Bonus);
        this.px.outer.setAttribute('data-tooltip-type', TooltipType.FactoryAccount);
        this.px.outer.setAttribute('data-tooltip-arguments', JSON.stringify([factory.id]));

        this.fi = document.createElement('div');

        this.node.href = `#screen=${ScreenType.Production}&id=${factory.id}`;
        this.node.appendChild(this.type.node);
        this.node.appendChild(this.location);
        this.node.appendChild(this.workers.node);
        this.node.appendChild(this.clerks.node);
        this.node.appendChild(this.px.outer);
        this.node.appendChild(this.fi);
    }

    public update(factory: FactoryTableEntry): void {
        UpdateText(this.type.summary, `${factory.type} (${factory.size_l})`);
        this.type.set(factory.size_p);

        UpdateText(this.location, factory.location);

        if (factory.workers === undefined) {
            this.workers.wage.updateBigInts(0n, 0n);
        } else {
            this.workers.wage.updateBigIntChange(factory.y_wn, factory.t_wn);
        }

        this.workers.update(factory.workers);

        if (factory.clerks === undefined) {
            this.clerks.wage.updateBigInts(0n, 0n);
        } else {
            this.clerks.wage.updateBigIntChange(factory.y_cn, factory.t_cn);
        }

        this.clerks.update(factory.clerks);

        this.px.updatePriceChange(factory.y_px, factory.t_px);
        if (factory.liquidating) {
            this.px.outer.setAttribute('data-cell', CellStyle.Bloody);
        } else {
            this.px.outer.removeAttribute('data-cell');
        }

        UpdatePrice(this.fi, factory.t_fi * 100, 1);
    }
}
