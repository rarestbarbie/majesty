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
    BuildingTableEntry,
    ProgressCell,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class BuildingTableRow implements DiffableListElement<GameID> {
    public readonly id: GameID;
    public readonly node: HTMLAnchorElement;

    private readonly label: HTMLSpanElement;
    private readonly level: HTMLSpanElement;

    private readonly type: ProgressCell;
    private readonly location: HTMLElement;
    private readonly size: Ticker;

    public static get columns(): string[] {
        return [
            "Type",
            "Location",
            "Size",
        ];
    }

    constructor(building: BuildingTableEntry) {
        this.id = building.id;
        this.node = document.createElement('a');

        this.label = document.createElement('span');
        this.level = document.createElement('span');
        this.level.classList.add('level');

        const summary = document.createElement('div');
        summary.appendChild(this.label);
        summary.appendChild(this.level);

        this.type = new ProgressCell(summary);
        this.type.node.setAttribute('data-tooltip-type', TooltipType.BuildingSize);
        this.type.node.setAttribute('data-tooltip-arguments', JSON.stringify([building.id]));
        this.location = document.createElement('div');


        this.size = new Ticker(Fortune.Bonus);
        this.size.outer.setAttribute('data-tooltip-type', TooltipType.BuildingAccount);
        this.size.outer.setAttribute('data-tooltip-arguments', JSON.stringify([building.id]));

        this.node.href = `#screen=${ScreenType.Infrastructure}&id=${building.id}`;
        this.node.appendChild(this.type.node);
        this.node.appendChild(this.location);
        this.node.appendChild(this.size.outer);
    }

    public update(building: BuildingTableEntry): void {
        UpdateText(this.label, `${building.type}`);
        UpdateText(this.location, building.location);

        this.size.updateBigIntChange(building.y_size, building.z_size);
    }
}
