import {
    Fortune,
    DiffableListElement,
    Ticker,
    UpdateBigInt,
    UpdateText,
    UpdateDecimal,
} from '../../DOM/exports.js';
import { GameID, hex } from '../../GameEngine/exports.js';
import {
    ProgressCell,
    PopIcon,
    PopTableEntry,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class PopTableRow implements DiffableListElement<GameID> {
    public readonly id: GameID;
    public readonly node: HTMLAnchorElement;

    private readonly size: Ticker;
    private readonly type: PopIcon;
    private readonly location: HTMLElement;
    private readonly nat: HTMLElement;
    private readonly mil: Ticker;
    private readonly con: Ticker;
    private readonly jobs: HTMLElement;
    private readonly cash: HTMLElement;
    private readonly fl: ProgressCell;
    private readonly fe: ProgressCell;
    private readonly fx: ProgressCell;

    public static get columns(): string[] {
        return [
            "Size",
            "Type",
            "Race",
            "Location",
            "Militancy",
            "Consciousness",
            "Unemployment",
            "Cash",
            "Needs",
            "",
            "",
        ];
    }

    constructor(pop: PopTableEntry) {
        this.id = pop.id;
        this.node = document.createElement('a');

        this.size = new Ticker(Fortune.Bonus);
        this.type = new PopIcon();

        this.location = document.createElement('div');
        this.nat = document.createElement('div');
        this.mil = new Ticker(Fortune.Malus);
        this.con = new Ticker(Fortune.Malus);

        this.jobs = document.createElement('div');
        this.jobs.setAttribute('data-tooltip-type', TooltipType.PopJobs);
        this.jobs.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));

        this.cash = document.createElement('div');
        this.cash.setAttribute('data-tooltip-type', TooltipType.PopAccount);
        this.cash.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));

        this.fl = new ProgressCell();
        this.fl.node.classList.add('needs-cup');
        this.fl.node.setAttribute('data-tooltip-type', TooltipType.PopNeeds);
        this.fl.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([pop.id, 'l'])
        );

        this.fe = new ProgressCell();
        this.fe.node.classList.add('needs-cup');
        this.fe.node.setAttribute('data-tooltip-type', TooltipType.PopNeeds);
        this.fe.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([pop.id, 'e'])
        );

        this.fx = new ProgressCell();
        this.fx.node.classList.add('needs-cup');
        this.fx.node.setAttribute('data-tooltip-type', TooltipType.PopNeeds);
        this.fx.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([pop.id, 'x'])
        );

        this.node.href = `#screen=${ScreenType.Population}&id=${pop.id}`;
        this.node.appendChild(this.size.outer);
        this.node.appendChild(this.type.node);
        this.node.appendChild(this.nat); // Comes before location!
        this.node.appendChild(this.location);
        this.node.appendChild(this.mil.outer);
        this.node.appendChild(this.con.outer);
        this.node.appendChild(this.jobs);
        this.node.appendChild(this.cash);
        this.node.appendChild(this.fl.node);
        this.node.appendChild(this.fe.node);
        this.node.appendChild(this.fx.node);
    }

    public update(pop: PopTableEntry): void {
        this.node.style.setProperty('--color', hex(pop.color));

        this.size.updateBigIntChange(pop.y_size, pop.t_size);
        this.type.set({ id: pop.id, type: pop.type });

        UpdateText(this.nat, pop.nat);
        UpdateText(this.location, pop.location);

        this.mil.updatePriceChange(pop.y_mil, pop.t_mil);
        this.con.updatePriceChange(pop.y_con, pop.t_con);

        UpdateDecimal(this.jobs, pop.une * 100, 2);

        const balance: bigint = pop.cash.liq +
            pop.cash.v +
            pop.cash.b +
            pop.cash.r +
            pop.cash.s +
            pop.cash.c +
            pop.cash.w +
            pop.cash.i;

        UpdateBigInt(this.cash, balance);

        UpdateDecimal(this.fl.summary, pop.t_fl * 100, 1);
        UpdateDecimal(this.fe.summary, pop.t_fe * 100, 1);
        UpdateDecimal(this.fx.summary, pop.t_fx * 100, 1);

        this.fl.set(pop.t_fl * 100);
        this.fe.set(pop.t_fe * 100);
        this.fx.set(pop.t_fx * 100);
    }
}
