import {
    PerspectiveCamera,
    Raycaster,
    Scene,
    Texture,
    WebGLRenderer,
    Vector2,
    Vector3,
} from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

import { GameID } from '../../GameEngine/GameID.js';
import {
    Application,
    CelestialBody,
    CelestialBodyState,
    CelestialViewState
} from '../exports.js';
import { Swift } from '../../Swift.js';

export class CelestialView {
    public readonly id: number;

    private readonly context: Application;

    private readonly system: GameID;
    private systemSize: number;
    private worlds: CelestialBody[];

    private readonly scene: Scene;
    private readonly camera: PerspectiveCamera;
    private readonly cameraControls: OrbitControls;
    private readonly raycaster: Raycaster;

    /// The ID of the most recently mousedown-ed celestial body.
    private mousedown: GameID | null;

    private static DOM = class {
        public readonly panel: HTMLDivElement;
        public readonly touch: HTMLDivElement;

        constructor() {
            this.touch = document.createElement('div');
            this.touch.className = 'touch';
            this.panel = document.createElement('div');
            this.panel.appendChild(this.touch);
        }

        public get X(): number {
            return this.panel.offsetLeft;
        }
        public get Y(): number {
            return window.innerHeight - this.panel.offsetTop - this.panel.clientHeight;
        }

        public get W(): number {
            return this.panel.clientWidth;
        }
        public get H(): number {
            return this.panel.clientHeight;
        }
    }

    private dom?: InstanceType<typeof CelestialView.DOM>;

    constructor(context: Application, id: number, system: GameID) {
        this.id = id;
        this.context = context;

        this.system = system;
        this.systemSize = 1;

        this.scene = new Scene();
        this.scene.scale.set(1, 1, 1);

        this.worlds = [];

        this.raycaster = new Raycaster();
        this.camera = new PerspectiveCamera( 40, 1, 1, 1000 );
        this.camera.up.set(0, 0, 1);

        this.cameraControls = new OrbitControls(this.camera);
        this.cameraControls.enableDamping = true;

        this.mousedown = null;
    }

    public attach(root: HTMLElement) {
        this.dom = new CelestialView.DOM();
        this.dom.panel.className = 'celestial-view';
        this.dom.panel.addEventListener('mousemove', this.onmousemove, false);

        this.dom.panel.addEventListener('mousedown', this.onmousedown, false);
        this.dom.panel.addEventListener('mouseup', this.onmouseup, false);

        this.cameraControls.connect(this.dom.touch);
        root.appendChild(this.dom.panel);
    }

    public detach() {
        if (!this.dom) {
            return;
        }

        for (const world of this.worlds) {
            world.detach();
        }
        this.worlds.length = 0;

        this.cameraControls.dispose();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    private raycast(event: MouseEvent): GameID | null {
        const target: HTMLElement = event.target as HTMLElement;
        const anchor: HTMLAnchorElement | null = target.closest<HTMLAnchorElement>('[data-planet]');
        const id: string | null = anchor?.getAttribute('data-planet') ?? null;

        if (id) {
            return parseInt(id, 10) as GameID;
        } else if (this.dom) {
            let mouse: Vector2 = new Vector2(
                (event.offsetX / this.dom.W) * 2 - 1,
                1 - (event.offsetY / this.dom.H) * 2,
            );

            // get the mouse position relative to canvas element
            this.raycaster.setFromCamera(mouse, this.camera);

            let planetSelected: GameID | null = null;
            let distanceSelected: number = Number.MAX_VALUE;
            // iterate over planets in reverse order to get the outermost one, if multiple orbit
            // lines are overlapping in the current camera view
            for (let i = this.worlds.length - 1; i >= 0; i--) {
                const world: CelestialBody = this.worlds[i];
                const distance: number | null = world.intersect(this.raycaster);
                if (distance === null) {
                    continue;
                }

                if (distance < distanceSelected) {
                    distanceSelected = distance;
                    planetSelected = world.id;
                }
            }

            return planetSelected;
        } else {
            return null;
        }
    }

    private onmousedown = (event: MouseEvent) => {
        const id: GameID | null = this.raycast(event);
        if (id) {
            this.mousedown = id;
        }
    };

    private onmouseup = (event: MouseEvent) => {
        const id: GameID | null = this.raycast(event);

        // Check if the press and release were on the same body
        if (id && id === this.mousedown && event.button === 0) {
            event.preventDefault();
            // If ctrlKey is pressed, switch context
            if (event.ctrlKey) {
                Swift.switch(id);
            } else {
                // Only open new tab from left pane
                if (this.id === 0) {
                    // Clicking on the sun closes the right pane
                    this.context.view(1, this.system === id ? null : id);
                }

                this.context.focus(id, null);
            }
        }

        // Always reset for the next interaction
        this.mousedown = null;
    };

    private onmousemove = (event: MouseEvent) => {
        if (!this.dom) {
            return;
        }

        const id: GameID | null = this.raycast(event);

        for (const world of this.worlds) {
            world.preselect(world.id === id);
        }

        if (id) {
            this.dom.panel.style.setProperty('cursor', 'pointer');
        } else {
            this.dom.panel.style.removeProperty('cursor');
        }
    }

    public select(id: GameID | null) {
        for (const world of this.worlds) {
            world.select(world.id === id);
        }
    }

    /// Resizes the scene view in response to changes in the DOM element size.
    public resize() {
        if (!this.dom) {
            return;
        }

        const W: number = this.dom.W;
        const H: number = this.dom.H;

        this.camera.aspect = W / H;
        this.camera.updateProjectionMatrix();
    }

    public draw(renderer: WebGLRenderer) {
        if (!this.dom) {
            return;
        }

        const X: number = this.dom.X;
        const Y: number = this.dom.Y;
        const W: number = this.dom.W;
        const H: number = this.dom.H;

        this.cameraControls.update();

        renderer.setScissorTest(true);
        renderer.setClearColor(0x000000, 0);

        // Set the viewport to the screen position of the root element
        renderer.setScissor(X, Y, W, H);
        renderer.setViewport(X, Y, W, H);
        renderer.clearColor();
        renderer.clearDepth(); // important!

        renderer.render(this.scene, this.camera);

        renderer.setScissorTest(false);

        // GUI
        // get 2d position of each planet
        for (const world of this.worlds) {
            world.sync(this.camera, this.dom.panel);
        }
    }

    public update(view: CelestialViewState) {
        if (!this.dom || view.bodies.length == 0) {
            return;
        }

        const remove: Map<GameID, CelestialBody> = new Map();
        for (const world of this.worlds) {
            remove.set(world.id, world);
        }

        this.worlds.length = 0;

        const insert: CelestialBody[] = [];
        for (const current of view.bodies) {

            let world: CelestialBody | undefined = remove.get(current.id);
            if (world) {
                remove.delete(world.id);
                world.state = current;
            } else {
                world = new CelestialBody(this.context, this.scene, current);
                insert.push(world);
            }

            const [x, y, z]: [number, number, number] = current.at;
            world.position = new Vector3(x, y, z);
            this.worlds.push(world);
        }

        // remove worlds that are no longer in the list
        for (const world of remove.values()) {
            world.detach();
        }
        // insert new worlds
        for (const world of insert) {
            world.attach(this.dom.panel, world.id != view.subject);
        }

        // This needs to be called after `attach(_:_:)`
        for (const world of this.worlds) {
            world.update();
        }

        this.calibrate(view.radius);
    }

    /// Calibrates the camera and controls based on the system size.
    private calibrate(systemSize: number) {
        if (this.systemSize === systemSize) {
            return;
        } else {
            this.systemSize = systemSize;
        }
        console.log(this.system, 'calibrated to', this.systemSize);
        // set camera distances based on the system size
        this.cameraControls.minDistance = 0.05 * this.systemSize;
        this.cameraControls.maxDistance = 5 * this.systemSize;

        this.camera.near = 0.01 * this.systemSize;
        this.camera.far = 50 * this.systemSize;

        this.camera.position.set( -20, 0, 30 );
        this.camera.updateProjectionMatrix();
    }
}
