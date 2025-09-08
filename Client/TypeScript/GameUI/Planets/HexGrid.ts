import { StaticList } from '../../DOM/exports.js';
import {
    HexGridCell,
    HexGridCellBackground,
    MinimapLayer,
    PlanetGridCell,
} from '../exports.js';

export class HexGrid {
    public readonly node: HTMLDivElement;
    private readonly svg: SVGSVGElement;
    private readonly cells: StaticList<HexGridCellBackground, string>;
    private readonly lines: StaticList<HexGridCell, string>;

    private static element<T extends keyof SVGElementTagNameMap>(
        type: T
    ): SVGElementTagNameMap[T] {
        return document.createElementNS('http://www.w3.org/2000/svg', type);
    }

    constructor() {
        this.svg = HexGrid.element('svg');
        this.svg.setAttribute('viewBox', `-15 -7.5 30 15`);

        this.cells = new StaticList<HexGridCellBackground, string>(HexGrid.element('g'));
        this.cells.node.classList.add('cells');
        this.lines = new StaticList<HexGridCell, string>(HexGrid.element('g'));
        this.lines.node.classList.add('lines');

        this.svg.appendChild(this.cells.node);
        this.svg.appendChild(this.lines.node);

        this.node = document.createElement('div');
        this.node.classList.add('hex-grid');
        this.node.appendChild(this.svg);
    }

    public switch(): void {
        // This is needed to update the data attributes on the interactive layer.
        // The background layer is just a dumb collection of colored polygons, so it doesn’t
        // need to be reset.
        this.lines.clear();
    }

    public update(
        cells: PlanetGridCell[],
        layer: MinimapLayer,
        prefix: any[],
        target: (id: string) => string | null = (_: string) => null,
        selected?: string,
    ): void {
        this.svg.setAttribute('data-layer', layer);
        this.cells.update(
            cells,
            (cell: PlanetGridCell) => new HexGridCellBackground(cell),
            (cell: PlanetGridCell, element: HexGridCellBackground) => {
                element.path.setAttribute('d', cell.d0);
                element.twin?.setAttribute('d', cell.d1 ?? '');
                element.update(cell);
            }
        );
        this.lines.update(
            cells,
            (cell: PlanetGridCell) => {
                const instance: HexGridCell = new HexGridCell(
                    cell,
                    [...prefix, cell.id, layer]
                );
                const href: string | null = target(cell.id);
                if (href) {
                    instance.node.setAttribute('href', href);
                }
                return instance;
            },
            (cell: PlanetGridCell, element: HexGridCell) => {
                element.path.setAttribute('d', cell.d0);
                element.twin?.setAttribute('d', cell.d1 ?? '');
            },
            selected,
        );
    }
}
