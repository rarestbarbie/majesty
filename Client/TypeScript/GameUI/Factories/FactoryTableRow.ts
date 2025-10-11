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

    private readonly label: HTMLSpanElement;
    private readonly level: HTMLSpanElement;

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

        this.label = document.createElement('span');
        this.level = document.createElement('span');
        this.level.classList.add('level');

        const summary = document.createElement('div');
        summary.appendChild(this.label);
        summary.appendChild(this.level);

        this.type = new ProgressCell(summary);
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
        UpdateText(this.label, `${factory.type}`);
        UpdateText(this.level, factory.size_l > 0 ? `${factory.size_l}` : '+');

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
        if (factory.liqf !== undefined) {
            this.type.node.classList.add(CellStyle.Bloody);
            this.type.set(factory.liqf * 100);
        } else {
            this.type.node.classList.remove(CellStyle.Bloody);
            this.type.set(factory.size_p);
        }

        UpdatePrice(this.fi, factory.t_fi * 100, 1);
    }
}
