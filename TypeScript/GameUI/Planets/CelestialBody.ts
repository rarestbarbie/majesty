import { Line2 } from 'three/addons/lines/Line2.js';
import { LineMaterial } from 'three/addons/lines/LineMaterial.js';
import { LineGeometry } from 'three/addons/lines/LineGeometry.js';
import {
    AdditiveBlending,
    Camera,
    Color,
    Intersection,
    MathUtils,
    Raycaster,
    Scene,
    Sprite,
    SpriteMaterial,
    Vector3,
} from 'three';

import { GameID } from '../../GameEngine/exports.js';
import { Swift } from '../../Swift.js';
import { Application, CelestialBodyState } from '../exports.js';

export class CelestialBody {
    private static readonly LINE_WIDTH: number = 1;

    public get id(): GameID {
        return this.state.id;
    }

    private readonly context: Application;
    private readonly scene: Scene;

    public readonly color: Color;
    public state: CelestialBodyState;
    public position?: Vector3;

    private dom?: {
        readonly orbit?: { display: Line2; hitbox: Line2 };
        readonly sprite: Sprite;
        readonly anchor: HTMLElement;
        readonly label: HTMLElement;
    };

    private preselected: boolean;
    private selected: boolean;

    constructor(context: Application, scene: Scene, state: CelestialBodyState) {
        this.context = context;
        this.scene = scene;
        this.state = state;
        this.color = new Color();

        this.preselected = false;
        this.selected = false;
    }

    public attach(root: HTMLDivElement, showLines: boolean) {
        if (this.dom) {
            throw new Error('CelestialBody already attached');
        }

        let orbit: { display: Line2; hitbox: Line2 } | undefined;
        let positions: Float32Array | null = showLines ? Swift.orbit(this.id) : null;
        if (positions) {
            const geometry = new LineGeometry();
            geometry.setPositions(positions);
            orbit = {
                display: new Line2(geometry, new LineMaterial({
                    // in world units with size attenuation, pixels otherwise
                    linewidth: CelestialBody.LINE_WIDTH,
                    alphaToCoverage: true,
                })),
                hitbox: new Line2(geometry, new LineMaterial({
                    linewidth: CelestialBody.LINE_WIDTH * 8,
                    transparent: true,
                    opacity: 0,
                    depthWrite: false,
                })),
            };
        }

        this.dom = {
            orbit: orbit,
            sprite: new Sprite(new SpriteMaterial({
                sizeAttenuation: false,
                blending: AdditiveBlending
            })),
            anchor: document.createElement('div'),
            label: document.createElement('div'),
        };
        this.dom.sprite.material.map = this.context.sprites.clone();

        this.scene.add(this.dom.sprite);
        if (this.dom.orbit) {
            this.scene.add(this.dom.orbit.display);
            this.scene.add(this.dom.orbit.hitbox);
        }

        this.dom.label.className = 'name';

        const circle: HTMLElement = document.createElement('div');
        circle.className = 'circle';

        this.dom.anchor.setAttribute('data-planet', `${this.id}`);
        this.dom.anchor.appendChild(circle);
        this.dom.anchor.appendChild(this.dom.label);

        root.appendChild(this.dom.anchor);
    }

    public detach() {
        if (!this.dom) {
            return;
        }

        this.scene.remove(this.dom.sprite);
        this.dom.sprite.geometry.dispose();
        this.dom.sprite.material.dispose();
        this.dom.sprite.material.map?.dispose();

        if (this.dom.orbit) {
            this.scene.remove(this.dom.orbit.display);
            this.scene.remove(this.dom.orbit.hitbox);
            this.dom.orbit.display.geometry.dispose();
            this.dom.orbit.display.material.dispose();
            this.dom.orbit.hitbox.geometry.dispose();
            this.dom.orbit.hitbox.material.dispose();
        }

        this.dom.anchor.remove();
        this.dom.label.remove();
        this.dom = undefined;
    }

    public update(): void {
        if (!this.dom ) {
            return;
        }

        let world: CelestialBodyState = this.state;

        this.dom.sprite.material.map?.offset.set(world.sprite_x / 8, world.sprite_y / 4);
        this.dom.sprite.material.map?.repeat.set(world.sprite_size / 8, world.sprite_size / 4);

        if (this.position) {
            this.dom.sprite.position.copy(this.position);
            const size: number = world.size * 0.4
                * world.sprite_size
                / world.sprite_disk;
            this.dom.sprite.scale.set(size, size, 1);
        }

        this.color.setHex(world.color);
        // Note: orbit path itself is currently not updated
        if (this.dom.orbit) {
            this.dom.orbit.display.material.color.set(this.color);
        }

        let r: number = 4 + world.size * 12.5 + Math.sqrt(world.size) * 10;

        this.dom.anchor.style.setProperty('--ui-color', `#${this.color.getHexString()}`);
        this.dom.anchor.style.setProperty('--ui-radius', `${r}px`);
        this.dom.label.textContent = world.name;
    }

    public sync(camera: Camera, view: HTMLElement) {
        if (!this.dom || !this.position) {
            return;
        }

        const s: Vector3 = this.position.clone();
        // we need to transform the position to screen space, which ranges from -1 to 1 in
        // the x and y axis
        s.project(camera);

        // rounding to the nearest 1e-9 helps with floating point precision issues, which
        // would otherwise cause the anchor to jitter around the screen
        const i: number = Math.round(s.x * 1_000_000_000) * 0.000_000_001;
        const j: number = Math.round(s.y * 1_000_000_000) * 0.000_000_001;

        // now we need to convert the x and y coordinates to 2d screen space, which ranges
        // from 0 to this.W and 0 to this.H
        const x: number = 1 * Math.round((i + 1) * view.offsetWidth / 2);
        const y: number = 1 * Math.round((1 - j) * view.offsetHeight / 2);
        // now we need to convert the x and y coordinates to CSS left and top properties
        this.dom.anchor.style.left = `${x}px`;
        this.dom.anchor.style.top = `${y}px`;
    }

    public intersect(raycaster: Raycaster): number | null {
        if (!this.dom?.orbit) {
            return null;
        }

        const intersects: Intersection[] = raycaster.intersectObject(this.dom.orbit.hitbox);
        if (intersects.length > 0) {
            return intersects[0].distance;
        } else {
            return null;
        }
    }

    public preselect(preselect: boolean) {
        this.preselected = preselect;
        this.highlight();
    }
    public select(select: boolean) {
        this.selected = select;
        this.highlight();
    }

    private highlight(): void {
        if (!this.dom) {
            return;
        }

        let width: number;

        if (this.selected || this.preselected) {
            this.dom.anchor.classList.add('selected');
            width = CelestialBody.LINE_WIDTH * 2;
        } else {
            this.dom.anchor.classList.remove('selected');
            width = CelestialBody.LINE_WIDTH;
        }

        if (this.dom.orbit) {
            this.dom.anchor.classList.remove('primary');
            this.dom.orbit.display.material.linewidth = width;
        } else {
            this.dom.anchor.classList.add('primary');
        }
    }
}
