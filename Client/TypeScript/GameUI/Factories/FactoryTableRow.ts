import {
    DiffableListElement,
    UpdateBigInt,
    UpdateText,
    UpdatePrice,
} from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    CashAccount,
    FactoryTableEntry,
    FactoryWorkersCell,
    ProgressCell,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class FactoryTableRow implements DiffableListElement<GameID> {
    public readonly id: GameID;
    public readonly node: HTMLAnchorElement;

    private readonly type: HTMLElement;
    private readonly location: HTMLElement;
    private readonly size: ProgressCell;
    private readonly workers: FactoryWorkersCell;
    private readonly clerks: FactoryWorkersCell;
    private readonly cash: HTMLElement;
    private readonly fi: HTMLElement;

    public static get columns(): string[] {
        return [
            "Type",
            "Location",
            "Level",
            "Workers",
            "Clerks",
            "Valuation",
            "Needs",
        ];
    }

    constructor(factory: FactoryTableEntry) {
        this.id = factory.id;
        this.node = document.createElement('a');

        this.type = document.createElement('div');
        this.location = document.createElement('div');

        this.size = new ProgressCell();
        this.size.node.setAttribute('data-tooltip-type', TooltipType.FactorySize);
        this.size.node.setAttribute('data-tooltip-arguments', JSON.stringify([factory.id]));

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

        this.cash = document.createElement('div');
        this.cash.setAttribute('data-tooltip-type', TooltipType.FactoryAccount);
        this.cash.setAttribute('data-tooltip-arguments', JSON.stringify([factory.id]));

        this.fi = document.createElement('div');

        this.node.href = `#screen=${ScreenType.Production}&id=${factory.id}`;
        this.node.appendChild(this.type);
        this.node.appendChild(this.location);
        this.node.appendChild(this.size.node);
        this.node.appendChild(this.workers.node);
        this.node.appendChild(this.clerks.node);
        this.node.appendChild(this.cash);
        this.node.appendChild(this.fi);
    }

    public update(factory: FactoryTableEntry): void {
        UpdateText(this.type, factory.type);
        UpdateText(this.location, factory.location);

        UpdateBigInt(this.size.summary, factory.size);
        this.size.set(factory.grow);

        this.workers.wn.updateBigIntChange(factory.y_wn, factory.t_wn);
        this.workers.update(factory.workers);

        this.clerks.wn.updateBigIntChange(factory.y_cn, factory.t_cn);
        this.clerks.update(factory.clerks);

        const cash: CashAccount = factory.cash;
        const liq: bigint = cash.liq +
            cash.v +
            cash.b +
            cash.r +
            cash.s +
            cash.c +
            cash.w +
            cash.i;

        UpdateBigInt(this.cash, liq + factory.t_vi + factory.t_vv);

        UpdatePrice(this.fi, factory.t_fi * 100, 1);
    }
}
