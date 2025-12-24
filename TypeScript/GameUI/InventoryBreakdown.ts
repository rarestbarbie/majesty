import {
    StaticList,
 } from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    InventoryBreakdownState,
    PersistentOverviewType,
    PopulationOverview,
    ResourceNeedMeter,
    ResourceNeedMeterState,
    ResourceNeedRow,
    ResourceNeed,
    ResourceSale,
    ResourceSaleBox,
    TooltipType,
} from './exports.js';


export class InventoryBreakdown {
    public readonly node: HTMLDivElement;

    private readonly tiers: StaticList<ResourceNeedMeter, string>;
    private readonly needs: StaticList<ResourceNeedRow, string>;
    private readonly sales: StaticList<ResourceSaleBox, string>;

    constructor() {
        this.tiers = new StaticList<ResourceNeedMeter, string>(document.createElement('div'));
        this.tiers.node.classList.add('tiers');

        this.needs = new StaticList<ResourceNeedRow, string>(document.createElement('div'));
        this.needs.node.setAttribute('data-table', 'Needs');

        const left: HTMLDivElement = document.createElement('div');
        left.classList.add('consumption');
        left.appendChild(this.tiers.node);
        left.appendChild(this.needs.node);

        this.sales = new StaticList<ResourceSaleBox, string>(document.createElement('div'));
        this.sales.node.classList.add('sales');

        this.node = document.createElement('div');
        this.node.classList.add('inventory');
        this.node.appendChild(left);
        this.node.appendChild(this.sales.node);
    }

    public clear(): void {
        // do we actually need this?
        this.sales.clear();
    }

    public update(id: GameID, state: InventoryBreakdownState<any>, type: PersistentOverviewType): void {
        this.tiers.update(
            state.tiers,
            (tier: ResourceNeedMeterState) => new ResourceNeedMeter(tier.id, type),
            (
                tier: ResourceNeedMeterState,
                meter: ResourceNeedMeter
            ) => meter.update(tier, id, type.screen),
            state.focus
        );
        this.needs.update(
            state.needs,
            (need: ResourceNeed) => new ResourceNeedRow(need, id, type),
            (need: ResourceNeed, row: ResourceNeedRow) => row.update(need, id),
        );
        this.sales.update(
            state.sales,
            (sale: ResourceSale) => new ResourceSaleBox(sale, id, type),
            (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale, id),
        );
    }
}
