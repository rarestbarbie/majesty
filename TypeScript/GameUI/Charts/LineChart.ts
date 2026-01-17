import {
    CreateSVG,
    FilterList,
    FilterTabs,
    StaticList,
    Term,
    TermState,
    UpdateText,
} from '../../DOM/exports.js';
import {
    GameID,
    GameDate
} from '../../GameEngine/exports.js';
import {
    ScreenContent,
    HexGrid,
    PlanetReport,
    PlanetFilter,
    PlanetFilterLabel,
    PlanetMapLayerSelector,
    ScreenType,
    PieChart,
    TimeSeriesFrame,
    TimeSeriesFrameState,
    TimeSeriesState,
    TooltipType,
    TickRule,
    TickRuleState
} from '../exports.js';

export class LineChart {
    public readonly type?: TooltipType;
    public readonly node: HTMLDivElement;

    private id?: any;
    private readonly markers: StaticList<TimeSeriesFrame, GameDate>;
    private readonly ticks: StaticList<TickRule, number>;
    private readonly lines: SVGPathElement;
    private readonly svg: SVGSVGElement;

    constructor(type?: TooltipType) {
        this.type = type;

        this.ticks = new StaticList<TickRule, number>(document.createElement('div'));
        this.ticks.node.classList.add('ticks');
        this.lines = CreateSVG('path');

        this.svg = CreateSVG('svg');
        this.svg.appendChild(this.lines);

        this.markers = new StaticList<TimeSeriesFrame, GameDate>(document.createElement('ul'));
        this.markers.node.classList.add('line-chart-markers');

        const markersContainer: HTMLDivElement = document.createElement('div');
        markersContainer.classList.add('line-chart-content');
        markersContainer.appendChild(this.svg);
        markersContainer.appendChild(this.markers.node);

        this.node = document.createElement('div');
        this.node.classList.add('line-chart');
        this.node.appendChild(markersContainer);
        this.node.appendChild(this.ticks.node);

        this.svg.setAttribute('viewBox', `-1 0 1 1`);
        this.svg.setAttribute('preserveAspectRatio', 'none');
    }

    public update(state: TimeSeriesState, id: any): void {
        if (this.id !== id) {
            this.id = id;
            this.markers.clear();
            this.ticks.clear();
        }

        const length: number = state.history.length;

        this.node.style.setProperty('--y-min', `${state.min}`);
        this.node.style.setProperty('--y-max', `${state.max}`);
        this.node.style.setProperty('--x-length', `${length}`);

        if (state.d === undefined) {
            this.lines.removeAttribute('d');
            this.lines.classList.add('empty');
        } else {
            this.lines.setAttribute('d', state.d);
            this.lines.classList.remove('empty');
        }
        this.markers.update(
            state.history,
            (interval: TimeSeriesFrameState) => new TimeSeriesFrame(interval, id, this.type),
            (interval: TimeSeriesFrameState, frame: TimeSeriesFrame) => frame.update(interval),
        );
        this.ticks.update(
            state.ticks,
            (state: TickRuleState) => new TickRule(state),
            (state: TickRuleState, tick: TickRule) => tick.update(state),
        );
    }
}
