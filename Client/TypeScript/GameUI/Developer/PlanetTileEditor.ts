
import { Swift } from '../../Swift.js';
import { PlanetTileEditorState } from '../exports.js';

export class PlanetTileEditor {
    public readonly node: HTMLDivElement;
    private readonly nameInput: HTMLInputElement;
    private readonly sizeInput: HTMLInputElement;
    private readonly terrainSelect: HTMLSelectElement;
    private readonly applyButton: HTMLButtonElement;

    // A copy of the last received editor state to send back on apply
    private lastReceivedState: PlanetTileEditorState | null = null;

    constructor() {
        this.node = document.createElement('div');
        this.node.id = 'tile-editor';
        this.node.style.display = 'none'; // Initially hidden

        const title = document.createElement('h4');
        title.textContent = 'Tile Editor';
        this.node.appendChild(title);

        // Tile Name
        const nameLabel = document.createElement('label');
        nameLabel.textContent = 'Name';
        this.nameInput = document.createElement('input');
        this.nameInput.type = 'text';
        nameLabel.appendChild(this.nameInput);
        this.node.appendChild(nameLabel);

        // Planet Size
        const sizeLabel = document.createElement('label');
        sizeLabel.textContent = 'Size';
        this.sizeInput = document.createElement('input');
        this.sizeInput.type = 'number';
        this.sizeInput.min = "0";
        sizeLabel.appendChild(this.sizeInput);
        this.node.appendChild(sizeLabel);

        // Terrain Type
        const terrainLabel = document.createElement('label');
        terrainLabel.textContent = 'Terrain';
        this.terrainSelect = document.createElement('select');
        terrainLabel.appendChild(this.terrainSelect);
        this.node.appendChild(terrainLabel);

        this.applyButton = document.createElement('button');
        this.applyButton.textContent = 'Apply Settings';
        this.applyButton.addEventListener('click', this.applySettings.bind(this));
        this.node.appendChild(this.applyButton);
    }

    public show(): void {
        this.node.style.display = 'flex';
    }

    public hide(): void {
        this.node.style.display = 'none';
    }

    public update(): void {
        const state: PlanetTileEditorState | null = Swift.editTerrain();

        if (state) {
            this.show();
        } else {
            this.hide();
            return;
        }

        this.lastReceivedState = state;

        this.nameInput.value = state.tile.name ?? '';
        this.sizeInput.value = state.size.toString();

        // Populate and set the terrain dropdown
        this.terrainSelect.innerHTML = '';
        for (let i = 0; i < state.terrainChoices.length; i++) {
            const option = document.createElement('option');
            // Use the terrain ID (number) as the value
            option.value = state.terrainChoices[i].toString();
            // Use the label from the parallel array as the text content
            option.textContent = state.terrainLabels[i];
            this.terrainSelect.appendChild(option);
        }
        this.terrainSelect.value = state.type.toString();
        this.show();
    }

    private applySettings(): void {
        if (!this.lastReceivedState) return;

        // Construct the object to send back, preserving the original structure
        const updatedEditorData: PlanetTileEditorState = {
            ...this.lastReceivedState, // Start with the last known state
            size: parseInt(this.sizeInput.value, 10),
            type: parseInt(this.terrainSelect.value, 10),
            tile: {
                ...this.lastReceivedState.tile, // Preserve other potential tile properties
                name: this.nameInput.value || undefined, // Set to undefined if empty
            }
        };

        Swift.loadTerrain(updatedEditorData);
    }
}
