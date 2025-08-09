import Stats from 'stats-gl';
import 'https://greggman.github.io/webgl-memory/webgl-memory.js';
import { Swift } from '../../Swift.js';
import { Application, PlanetTileEditor } from '../exports.js';

export class DeveloperToolsPanel {
    public readonly node: HTMLDivElement;

    private readonly memoryUI: HTMLDListElement;
    private readonly memory: any;
    private readonly stats: Stats;

    private readonly tile: PlanetTileEditor;

    private readonly context: Application;
    private visible: boolean = false;

    constructor(context: Application) {
        this.memory = context.renderer.getContext().getExtension('GMAN_webgl_memory');
        this.memoryUI = document.createElement('dl');
        this.memoryUI.id = 'debug-memory';

        this.stats = new Stats({ horizontal: false, trackGPU: true });
        this.stats.dom.id = 'debug-stats';
        this.stats.dom.removeAttribute('style');
        this.stats.init(context.renderer);

        this.node = document.createElement('div');
        this.node.id = 'devtools';
        this.node.style.display = 'none';
        this.visible = false;

        const title: HTMLHeadingElement = document.createElement('h3');
        title.textContent = 'Developer Tools';

        const exportButton: HTMLButtonElement = document.createElement('button');
        exportButton.textContent = 'Save terrain';
        exportButton.addEventListener('click', () => this.exportTerrain(false));

        const downloadButton: HTMLButtonElement = document.createElement('button');
        downloadButton.textContent = 'Download terrain';
        downloadButton.addEventListener('click', () => this.exportTerrain(true));

        this.tile = new PlanetTileEditor();

        this.node.appendChild(title);
        this.node.appendChild(exportButton);
        this.node.appendChild(downloadButton);
        this.node.appendChild(this.tile.node);
        this.node.appendChild(this.memoryUI);
        this.node.appendChild(this.stats.dom);

        this.context = context;
    }

    public draw(): void {
        this.stats.update();

        const info: any = this.memory.getMemoryInfo();
        this.memoryUI.replaceChildren();
        for (const [key, value] of Object.entries(info.memory)) {
            const dt: HTMLElement = document.createElement('dt');
            dt.innerText = key;
            this.memoryUI.appendChild(dt);

            const dd: HTMLElement = document.createElement('dd');
            dd.innerText = JSON.stringify(value);
            this.memoryUI.appendChild(dd);
        }
    }

    public toggle(): void {
        this.visible = !this.visible;
        this.node.style.display = this.visible ? 'block' : 'none';
    }

    public refresh(): void {
        this.tile.update();
    }

    private async exportTerrain(download: boolean): Promise<void> {
        const serializedTerrain: any[] | null = Swift.saveTerrain();
        if (serializedTerrain === null) {
            console.error("Failed to export terrain data from Swift.");
            return;
        }

        if (download) {
            const json: string = JSON.stringify(serializedTerrain, null, 4);
            const blob: Blob = new Blob([json], { type: 'application/json' });
            const url: string = URL.createObjectURL(blob);

            const a: HTMLAnchorElement = document.createElement('a');
            a.href = url;
            a.download = 'terrain.json';

            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);

            URL.revokeObjectURL(url);
            return;
        }

        try {
            await this.context.persistence.saveTerrain(serializedTerrain);
            alert("Terrain saved successfully!");
        } catch (error) {
            console.error("Failed to save terrain to cloud:", error);
            alert(`Error saving terrain: ${error}`);
        }
    }
}
