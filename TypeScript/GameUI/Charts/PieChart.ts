import * as GameEngine from '../../GameEngine/exports.js';
import {
    CreateSVG,
    StaticList,
} from '../../DOM/exports.js';

import {
    PieChartComponent,
    PieChartSector,
    TooltipType,
} from '../exports.js';

export class PieChart<Sector> {
    public readonly node: HTMLDivElement;

    private id?: any;
    private readonly type: TooltipType;
    private readonly sectors: StaticList<PieChartComponent<Sector>, Sector>;

    constructor(type: TooltipType) {
        this.type = type;

        const svg: SVGSVGElement = CreateSVG('svg');
        const g: SVGGElement = CreateSVG('g');

        svg.setAttribute('viewBox', '-1 -1 2 2');
        svg.appendChild(g);

        this.sectors = new StaticList<PieChartComponent<Sector>, Sector>(g);

        this.node = document.createElement('div');
        this.node.classList.add('pie-chart');
        this.node.classList.add('empty');
        this.node.appendChild(svg);
    }

    public update(sectors: PieChartSector<Sector>[], id: any): void {
        if (sectors.length === 0) {
            this.node.classList.add('empty');
        } else {
            this.node.classList.remove('empty');
        }

        if (this.id !== id) {
            this.id = id;
            this.sectors.clear();
        }

        this.sectors.update(
            sectors,
            (sector: PieChartSector<Sector>) => {
                const node: SVGGElement = CreateSVG('g');
                node.setAttribute('data-tooltip-type', this.type);
                node.setAttribute('data-tooltip-arguments', JSON.stringify([id, sector.id]));
                return { id: sector.id, node: node };
            },
            (sector: PieChartSector<Sector>, element: PieChartComponent<Sector>) => {
                if (sector.d) {
                    if (!(element.geometry instanceof SVGPathElement)) {
                        element.geometry?.remove();
                        element.geometry = CreateSVG('path');
                        element.node.appendChild(element.geometry);
                    }

                    element.geometry.setAttribute('d', sector.d);
                } else {
                    if (!(element.geometry instanceof SVGCircleElement)) {
                        element.geometry?.remove();
                        element.geometry = CreateSVG('circle');
                        element.node.appendChild(element.geometry);
                    }

                    element.geometry.setAttribute('r', '1');
                }

                if (sector.value.color !== undefined) {
                    element.geometry.setAttribute('fill', GameEngine.hex(sector.value.color));
                }
                if (sector.value.style !== undefined) {
                    element.geometry.setAttribute('class', sector.value.style);
                }
            },
        );
    }
}
