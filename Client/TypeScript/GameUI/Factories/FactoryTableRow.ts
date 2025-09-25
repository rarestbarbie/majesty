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
    private readonly px: Ticker;
    private readonly fi: HTMLElement;

    public static get columns(): string[] {
        return [
            "Type",
            "Location",
            "Level",
            "Workers",
            "Clerks",
            "Share price",
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

        this.px = new Ticker(Fortune.Bonus);
        this.px.outer.setAttribute('data-tooltip-type', TooltipType.FactoryAccount);
        this.px.outer.setAttribute('data-tooltip-arguments', JSON.stringify([factory.id]));

        this.fi = document.createElement('div');

        this.node.href = `#screen=${ScreenType.Production}&id=${factory.id}`;
        this.node.appendChild(this.type);
        this.node.appendChild(this.location);
        this.node.appendChild(this.size.node);
        this.node.appendChild(this.workers.node);
        this.node.appendChild(this.clerks.node);
        this.node.appendChild(this.px.outer);
        this.node.appendChild(this.fi);
    }

    public update(factory: FactoryTableEntry): void {
        UpdateText(this.type, factory.type);
        UpdateText(this.location, factory.location);

        UpdateBigInt(this.size.summary, factory.size_l);
        this.size.set(factory.size_p);

        this.workers.wn.updateBigIntChange(factory.y_wn, factory.t_wn);
        this.workers.update(factory.workers);

        this.clerks.wn.updateBigIntChange(factory.y_cn, factory.t_cn);
        this.clerks.update(factory.clerks);

        this.px.updatePriceChange(factory.y_px, factory.t_px);
        UpdatePrice(this.fi, factory.t_fi * 100, 1);
    }
}
