import { StaticList } from '../../DOM/exports.js';
import { GameID } from "../../GameEngine/GameID.js";
import { ScreenContent } from "../ScreenContent.js";
import { Swift } from "../../Swift.js";
import {
    PopulationReport,
    PopTableEntry,
    PopTableRow,
    ResourceNeed,
    ResourceNeedRow,
    ResourceSale,
    ResourceSaleBox,
    Resource,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class PopulationOverview extends ScreenContent {
    private needs: StaticList<ResourceNeedRow, Resource>;
    private sales: StaticList<ResourceSaleBox, Resource>;
    private pops: StaticList<PopTableRow, GameID>;
    private dom?: {
        readonly index: HTMLUListElement;
        readonly panel: HTMLDivElement;
        readonly stats: HTMLDivElement;
    };

    constructor() {
        super();

        this.pops = new StaticList<PopTableRow, GameID>(document.createElement("div"));
        this.pops.table('Pops', PopTableRow.columns);

        this.needs = new StaticList<ResourceNeedRow, Resource>(document.createElement("div"));
        this.sales = new StaticList<ResourceSaleBox, Resource>(document.createElement("div"));
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        let subject: string | null = parameters.get('id');
        let state: PopulationReport = Swift.openPopulation(
            subject ? parseInt(subject) as GameID : null,
        );

        // We need to empty the upper content, as we will need to replace the IDs.
        this.needs.table('Needs', ResourceNeedRow.columns);
        this.sales.boxes('Sales');

        if (!this.dom) {
            this.dom = {
                index: document.createElement("ul"),
                panel: document.createElement("div"),
                stats: document.createElement("div"),
            }

            this.dom.stats.appendChild(this.needs.node);
            this.dom.stats.appendChild(this.sales.node);

            this.dom.panel.appendChild(this.dom.stats);
            this.dom.panel.appendChild(this.pops.node);
        }
        if (root) {
            root.appendChild(this.dom.index);
            root.appendChild(this.dom.panel);
        }

        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error("PopulationOverview not attached");
        }

        this.dom.index.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: PopulationReport): void {
        if (!this.dom || state.pops.length == 0) {
            return;
        }

        this.pops.update(
            state.pops,
            (pop: PopTableEntry) => new PopTableRow(pop),
            (pop: PopTableEntry, row: PopTableRow) => row.update(pop),
            state.pop?.id
        );

        if (state.pop) {
            const id: GameID = state.pop.id;
            this.needs.update(
                state.pop.needs,
                (need: ResourceNeed) => new ResourceNeedRow(
                    need,
                    id,
                    TooltipType.PopDemand,
                    TooltipType.PopStockpile,
                ),
                (need: ResourceNeed, row: ResourceNeedRow) => row.update(need),
            );

            this.sales.update(
                state.pop.sales,
                (sale: ResourceSale) => new ResourceSaleBox(sale),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale),
            );
        }
    }
}
