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

    private readonly typeLabel: HTMLSpanElement;
    private readonly type: ProgressCell;
    private readonly location: HTMLElement;
    private readonly vacant: Ticker;
    private readonly active: Ticker;

    public static get columns(): string[] {
        return [
            "Type",
            "Location",
            "Vacant",
            "Active",
        ];
    }

    constructor(building: BuildingTableEntry) {
        this.id = building.id;
        this.node = document.createElement('a');

        this.typeLabel = document.createElement('span');

        const summary = document.createElement('div');
        summary.appendChild(this.typeLabel);

        this.type = new ProgressCell(summary);
        this.type.node.setAttribute('data-tooltip-type', TooltipType.BuildingAccount);
        this.type.node.setAttribute('data-tooltip-arguments', JSON.stringify([building.id]));
        this.location = document.createElement('div');


        this.vacant = new Ticker(Fortune.Bonus);
        this.vacant.outer.setAttribute('data-tooltip-type', TooltipType.BuildingVacant);
        this.vacant.outer.setAttribute('data-tooltip-arguments', JSON.stringify([building.id]));

        this.active = new Ticker(Fortune.Bonus);
        this.active.outer.setAttribute('data-tooltip-type', TooltipType.BuildingActive);
        this.active.outer.setAttribute('data-tooltip-arguments', JSON.stringify([building.id]));

        this.node.href = `#screen=${ScreenType.Infrastructure}&id=${building.id}`;
        this.node.appendChild(this.type.node);
        this.node.appendChild(this.location);
        this.node.appendChild(this.vacant.outer);
        this.node.appendChild(this.active.outer);
    }

    public update(building: BuildingTableEntry): void {
        UpdateText(this.typeLabel, `${building.type}`);
        this.type.set(100 * building.progress);

        UpdateText(this.location, building.location);

        this.vacant.updateBigIntChange(building.y_vacant, building.z_vacant);
        this.active.updateBigIntChange(building.y_active, building.z_active);
    }
}
