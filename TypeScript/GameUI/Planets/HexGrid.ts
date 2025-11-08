import { StaticList } from '../../DOM/exports.js';
import {
    ContextMenuType,
    HexGridCell,
    HexGridCellBackground,
    MinimapLayer,
    PlanetMapTileState,
    TooltipType,
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
        tiles: PlanetMapTileState[],
        layer: MinimapLayer,
        prefix: any[],
        target: (id: string) => string | null = (_: string) => null,
        selected?: string,
        neighbors?: Map<string, number>,
    ): void {
        this.svg.setAttribute('data-layer', layer);
        this.cells.update(
            tiles,
            (tile: PlanetMapTileState) => new HexGridCellBackground(tile),
            (tile: PlanetMapTileState, element: HexGridCellBackground) => {
                element.path.setAttribute('d', tile.d0);
                element.twin?.setAttribute('d', tile.d1 ?? '');
                element.update(tile);
            }
        );

        this.lines.update(
            tiles,
            (tile: PlanetMapTileState) => {
                const cell: HexGridCell = new HexGridCell(tile);
                const href: string | null = target(tile.id);
                if (href !== null) {
                    cell.node.setAttribute('href', href);
                }

                const path: string = JSON.stringify([...prefix, tile.id, layer]);

                cell.node.setAttribute('data-tooltip-type', TooltipType.PlanetCell);
                cell.node.setAttribute('data-tooltip-arguments', path);
                cell.node.setAttribute('data-menu-type', ContextMenuType.MinimapTile);
                cell.node.setAttribute('data-menu-arguments', path);
                return cell;
            },
            (tile: PlanetMapTileState, element: HexGridCell) => {
                element.path.setAttribute('d', tile.d0);
                element.twin?.setAttribute('d', tile.d1 ?? '');

                const neighbor: number | undefined = neighbors?.get(tile.id);
                if (neighbor !== undefined) {
                    element.node.setAttribute('data-neighbor-index', `${neighbor}`);
                } else {
                    element.node.removeAttribute('data-neighbor-index');
                }
            },
            selected,
        );
    }
}
