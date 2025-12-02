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
    ProgressTriad,
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

    /// Location cell doubles as the background for the unemployment meter
    private readonly location: ProgressCell;
    private readonly nat: HTMLElement;
    private readonly mil: Ticker;
    private readonly con: Ticker;
    private readonly needs: ProgressTriad;

    constructor(pop: PopTableEntry) {
        this.id = pop.id;
        this.node = document.createElement('a');

        this.size = new Ticker(Fortune.Bonus);
        this.type = new PopIcon();
        this.nat = document.createElement('div');
        this.nat.setAttribute('data-tooltip-type', TooltipType.PopAccount);
        this.nat.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));

        this.location = new ProgressCell();
        this.location.node.setAttribute('data-tooltip-type', TooltipType.PopJobs);
        this.location.node.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));

        this.mil = new Ticker(Fortune.Malus);
        this.con = new Ticker(Fortune.Malus);

        this.needs = new ProgressTriad(pop.id, TooltipType.PopNeeds);

        this.node.href = `#screen=${ScreenType.Population}&id=${pop.id}`;
        this.node.appendChild(this.size.outer);
        this.node.appendChild(this.type.node);
        this.node.appendChild(this.nat); // Comes before location!
        this.node.appendChild(this.location.node);
        this.node.appendChild(this.mil.outer);
        this.node.appendChild(this.con.outer);
        this.node.appendChild(this.needs.node);
    }

    public update(pop: PopTableEntry): void {
        this.node.style.setProperty('--color', hex(pop.color));

        this.size.updateBigIntChange(pop.y_size, pop.t_size);
        this.type.set({ id: pop.id, type: pop.type });

        UpdateText(this.nat, pop.nat);

        UpdateText(this.location.summary, pop.location);
        this.location.set(pop.une * 100);

        this.mil.updatePriceChange(pop.y_mil, pop.t_mil);
        this.con.updatePriceChange(pop.y_con, pop.t_con);

        this.needs.set(100 * pop.t_fl, 100 * pop.t_fe, 100 * pop.t_fx);
    }
}
