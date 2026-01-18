import {
    CreateSVG,
    FilterList,
    FilterTabs,
    StaticList,
    Term,
    TermState,
    UpdateText,
} from '../../DOM/exports.js';
import { UpdateColorReference } from '../../GameEngine/exports.js';
import { GameDate } from '../../GameEngine/exports.js';
import {
    ScreenContent,
    HexGrid,
    TimeSeriesChannel,
    PlanetReport,
    PlanetFilter,
    PlanetFilterLabel,
    PlanetMapLayerSelector,
    ScreenType,
    PieChart,
    TimeSeriesChannelState,
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
    private readonly lines: StaticList<TimeSeriesChannel<number>, number>;
    private readonly svg: SVGSVGElement;

    constructor(type?: TooltipType) {
        this.type = type;

        this.ticks = new StaticList<TickRule, number>(document.createElement('div'));
        this.ticks.node.classList.add('ticks');
        this.lines = new StaticList<TimeSeriesChannel<number>, number>(CreateSVG('g'));

        this.svg = CreateSVG('svg');
        this.svg.appendChild(this.lines.node);

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

        const primary: TimeSeriesChannelState<number> | undefined = state.channels[0];
        if (primary === undefined || primary.frames === undefined) {
            return;
        }

        const length: number = primary.frames.length;

        this.node.style.setProperty('--y-min', `${state.min}`);
        this.node.style.setProperty('--y-max', `${state.max}`);
        this.node.style.setProperty('--x-length', `${length}`);

        this.markers.update(
            primary.frames,
            (interval: TimeSeriesFrameState) => new TimeSeriesFrame(interval, id, this.type),
            (interval: TimeSeriesFrameState, frame: TimeSeriesFrame) => frame.update(interval),
        );
        this.lines.update(
            state.channels,
            (series: TimeSeriesChannelState<number>): TimeSeriesChannel<number> => {
                const node: SVGPathElement = CreateSVG('path');
                return { id: series.id, node };
            },
            (series: TimeSeriesChannelState<number>, channel: TimeSeriesChannel<number>) => {
                if (series.label !== undefined) {
                    UpdateColorReference(channel.node, series.label);
                }
                channel.node.setAttribute('d', series.d);
            }
        );
        this.ticks.update(
            state.ticks,
            (state: TickRuleState) => new TickRule(state),
            (state: TickRuleState, tick: TickRule) => tick.update(state),
        );
    }
}
