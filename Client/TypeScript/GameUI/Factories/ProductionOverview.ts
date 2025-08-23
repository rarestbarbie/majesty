import {
    StaticList,
} from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/GameID.js';
import { ScreenContent } from '../ScreenContent.js';
import { Swift } from '../../Swift.js';
import {
    FactoryTableEntry,
    FactoryTableRow,
    FactoryDetailsTab,
    PieChart,
    ProductionReport,
    ResourceNeed,
    ResourceNeedRow,
    ResourceSale,
    ResourceSaleBox,
    Resource,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class ProductionOverview extends ScreenContent {
    private readonly factories: StaticList<FactoryTableRow, GameID>;
    private readonly needs: StaticList<ResourceNeedRow, Resource>;
    private readonly sales: StaticList<ResourceSaleBox, Resource>;
    private readonly charts: {
        readonly spending: PieChart<string>;
        readonly country: PieChart<GameID>;
        readonly culture: PieChart<string>;
    };

    private dom?: {
        readonly index: HTMLUListElement;
        readonly panel: HTMLDivElement;
        readonly stats: HTMLDivElement;
    };

    constructor() {
        super();
        this.factories = new StaticList<FactoryTableRow, GameID>(document.createElement('div'));
        this.factories.table('Factories', FactoryTableRow.columns);

        this.needs = new StaticList<ResourceNeedRow, Resource>(document.createElement('div'));
        this.sales = new StaticList<ResourceSaleBox, Resource>(document.createElement('div'));

        this.charts = {
            spending: new PieChart<string>(TooltipType.FactoryStatementItem),
            country: new PieChart<GameID>(TooltipType.FactoryOwnershipCountry),
            culture: new PieChart<string>(TooltipType.FactoryOwnershipCulture),
        }
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        const factory: string | null = parameters.get('id');
        const state: ProductionReport = Swift.openProduction(
            factory ? parseInt(factory) as GameID : null,
            parameters.get('details') as FactoryDetailsTab
        );

        this.needs.table('Needs', ResourceNeedRow.columns);
        this.sales.boxes('Sales');

        if (!this.dom) {
            this.dom = {
                index: document.createElement('ul'),
                panel: document.createElement('div'),
                stats: document.createElement('div'),
            }

            this.dom.panel.appendChild(this.dom.stats);
            this.dom.panel.appendChild(this.factories.node);
        } else {
            this.dom.stats.replaceChildren();
        }

        const nav: HTMLElement = document.createElement('nav');
        for (const tab of [FactoryDetailsTab.Inventory, FactoryDetailsTab.Ownership]) {
            const link: HTMLAnchorElement = document.createElement('a');
            link.href = `#screen=${ScreenType.Production}&details=${tab}`;
            link.textContent = tab;

            if (tab == state.factory?.open.type) {
                link.classList.add('selected');
            }

            nav.appendChild(link);
        }

        switch (state.factory?.open.type) {
        case FactoryDetailsTab.Inventory:
            this.dom.stats.appendChild(this.needs.node);
            this.dom.stats.appendChild(this.sales.node);
            this.dom.stats.appendChild(this.charts.spending.node);
            break;

        case FactoryDetailsTab.Ownership:
            this.dom.stats.appendChild(this.charts.country.node);
            this.dom.stats.appendChild(this.charts.culture.node);
            break;
        }

        this.dom.stats.appendChild(nav);

        if (root) {
            root.appendChild(this.dom.index);
            root.appendChild(this.dom.panel);
        }

        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error('ProductionOverview not attached');
        }

        this.dom.index.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: ProductionReport): void {
        if (!this.dom || state.factories.length == 0) {
            return;
        }

        this.factories.update(
            state.factories,
            (factory: FactoryTableEntry) => new FactoryTableRow(factory),
            (factory: FactoryTableEntry, row: FactoryTableRow) => row.update(factory),
            state.factory?.id
        );

        switch (state.factory?.open.type) {
        case FactoryDetailsTab.Inventory:
            let id: GameID = state.factory.id;

            this.needs.update(
                state.factory.open.needs,
                (need: ResourceNeed) => new ResourceNeedRow(
                    need,
                    id,
                    TooltipType.FactoryDemand,
                    TooltipType.FactoryStockpile,
                ),
                (need: ResourceNeed, row: ResourceNeedRow) => row.update(need),
            );
            this.sales.update(
                state.factory.open.sales,
                (sale: ResourceSale) => new ResourceSaleBox(sale),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale),
            );

            this.charts.spending.update([id], state.factory.open.spending ?? []);
            break;

        case FactoryDetailsTab.Ownership:
            this.charts.country.update([state.factory.id], state.factory.open.country ?? []);
            this.charts.culture.update([state.factory.id], state.factory.open.culture ?? []);
            break;
        }
    }
}
