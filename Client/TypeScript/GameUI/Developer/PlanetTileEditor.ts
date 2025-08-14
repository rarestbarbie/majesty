import { Swift } from '../../Swift.js';
import { PlanetTileEditorState } from '../exports.js';

export class PlanetTileEditor {
    public readonly node: HTMLDivElement;
    private readonly nameInput: HTMLInputElement;
    private readonly sizeInput: HTMLInputElement;
    private readonly rotateFieldset: HTMLFieldSetElement;
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

        // Group for "Selected Tile Properties"
        const tilePropertiesGroup = document.createElement('div');
        const tilePropertiesHeader = document.createElement('h5');
        tilePropertiesHeader.textContent = 'Selected Tile Properties';
        tilePropertiesGroup.appendChild(tilePropertiesHeader);

        const nameLabel = document.createElement('label');
        nameLabel.textContent = 'Name';
        this.nameInput = document.createElement('input');
        this.nameInput.type = 'text';
        nameLabel.appendChild(this.nameInput);
        tilePropertiesGroup.appendChild(nameLabel);

        const terrainLabel = document.createElement('label');
        terrainLabel.textContent = 'Terrain';
        this.terrainSelect = document.createElement('select');
        terrainLabel.appendChild(this.terrainSelect);
        tilePropertiesGroup.appendChild(terrainLabel);
        this.node.appendChild(tilePropertiesGroup);

        // Group for "Global Grid Actions"
        const gridActionsGroup = document.createElement('div');
        const gridActionsHeader = document.createElement('h5');
        gridActionsHeader.textContent = 'Global Grid Actions';
        gridActionsGroup.appendChild(gridActionsHeader);

        const sizeLabel = document.createElement('label');
        sizeLabel.textContent = 'Size';
        this.sizeInput = document.createElement('input');
        this.sizeInput.type = 'number';
        this.sizeInput.min = "0";
        sizeLabel.appendChild(this.sizeInput);
        gridActionsGroup.appendChild(sizeLabel);

        // Rotation Radio Buttons
        this.rotateFieldset = document.createElement('fieldset');
        const rotateLegend = document.createElement('legend');
        rotateLegend.textContent = 'Rotate Tiles';
        this.rotateFieldset.appendChild(rotateLegend);

        const rotations = [
            { label: 'None', value: 'none', checked: true },
            { label: 'Clockwise ↻', value: 'cw', checked: false },
            { label: 'Counter-Clockwise ↺', value: 'ccw', checked: false }
        ];

        rotations.forEach(rot => {
            const wrapper = document.createElement('div');
            const input = document.createElement('input');
            input.type = 'radio';
            input.name = 'rotation';
            input.id = `rotate-${rot.value}`;
            input.value = rot.value;
            input.checked = rot.checked;

            const label = document.createElement('label');
            label.htmlFor = `rotate-${rot.value}`;
            label.textContent = rot.label;

            wrapper.appendChild(input);
            wrapper.appendChild(label);
            this.rotateFieldset.appendChild(wrapper);
        });
        gridActionsGroup.appendChild(this.rotateFieldset);
        this.node.appendChild(gridActionsGroup);


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

        const polar: boolean = state.id === 'N0,0' || state.id === 'S0,0';

        this.sizeInput.disabled = !polar;
        this.rotateFieldset.disabled = !polar;

        const disabledTooltip: string = 'Select a polar tile to modify the grid.';
        this.sizeInput.title = polar ? '' : disabledTooltip;
        this.rotateFieldset.title = polar ? '' : disabledTooltip;

        this.nameInput.value = state.tile.name ?? '';
        this.sizeInput.value = state.size.toString();

        // Reset rotation to 'None'
        (this.rotateFieldset.querySelector('input[value="none"]') as HTMLInputElement).checked = true;

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

        const selectedRotation = (this.rotateFieldset.querySelector('input[name="rotation"]:checked') as HTMLInputElement).value;
        let rotateValue: boolean | undefined;
        if (selectedRotation === 'cw') {
            rotateValue = false;
        } else if (selectedRotation === 'ccw') {
            rotateValue = true;
        } else {
            rotateValue = undefined;
        }

        // Construct the object to send back, preserving the original structure
        const updatedEditorData: PlanetTileEditorState = {
            ...this.lastReceivedState, // Start with the last known state
            rotate: rotateValue,
            size: parseInt(this.sizeInput.value, 10),
            type: parseInt(this.terrainSelect.value, 10),
            tile: {
                ...this.lastReceivedState.tile, // Preserve other potential tile properties
                name: this.nameInput.value || undefined, // Set to undefined if empty
            }
        };

        Swift.loadTerrain(updatedEditorData);

        // Visual feedback
        this.applyButton.textContent = 'Applied!';
        this.applyButton.style.backgroundColor = '#20d08d';
        setTimeout(() => {
            this.applyButton.textContent = 'Apply Settings';
            this.applyButton.style.backgroundColor = '';
        }, 1000);
    }
}
