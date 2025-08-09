import * as GameEngine from '../../GameEngine/exports.js';
import {
    StaticList,
} from '../../DOM/exports.js';

import {
    PieChartComponent,
    PieChartSector,
    PieChartType,
    TooltipBuilderKey,
} from '../exports.js';

export class PieChart<Sector> {
    public readonly id: PieChartType;
    public readonly node: HTMLDivElement;

    private readonly sectors: StaticList<PieChartComponent<Sector>, Sector>;

    private static element<T extends keyof SVGElementTagNameMap>(
        type: T
    ): SVGElementTagNameMap[T] {
        return document.createElementNS('http://www.w3.org/2000/svg', type);
    }

    constructor(id: PieChartType) {
        this.id = id;

        const svg: SVGSVGElement = PieChart.element('svg');
        const g: SVGGElement = PieChart.element('g');

        svg.setAttribute('viewBox', '-1 -1 2 2');
        svg.appendChild(g);

        this.sectors = new StaticList<PieChartComponent<Sector>, Sector>(g);

        this.node = document.createElement('div');
        this.node.classList.add('pie-chart');
        this.node.style.position = 'relative';
        this.node.appendChild(svg);
    }

    public update(prefix: any[], sectors: PieChartSector<Sector>[]): void {
        this.sectors.update(
            sectors,
            (sector: PieChartSector<Sector>) => {
                return { id: sector.id, node: PieChart.element('g') };
            },
            (sector: PieChartSector<Sector>, element: PieChartComponent<Sector>) => {
                if (sector.d) {
                    if (!(element.geometry instanceof SVGPathElement)) {
                        element.geometry?.remove();
                        element.geometry = PieChart.element('path');
                        element.node.appendChild(element.geometry);
                    }

                    element.geometry.setAttribute('d', sector.d);
                } else {
                    if (!(element.geometry instanceof SVGCircleElement)) {
                        element.geometry?.remove();
                        element.geometry = PieChart.element('circle');
                        element.node.appendChild(element.geometry);
                    }

                    element.geometry.setAttribute('r', '1');
                }

                element.geometry.setAttribute('fill', GameEngine.hex(sector.value.color));

                let type: TooltipBuilderKey
                switch (this.id) {
                case PieChartType.Country:
                    type = TooltipBuilderKey.FactoryOwnershipCountry;
                    break;
                case PieChartType.Culture:
                    type = TooltipBuilderKey.FactoryOwnershipCulture;
                    break;
                }

                element.node.setAttribute('data-tooltip-type', type);
                element.node.setAttribute(
                    'data-tooltip-arguments',
                    JSON.stringify([...prefix, sector.id])
                );
            },
        );
    }
}
