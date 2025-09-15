import { Swift } from '../../Swift.js';
import { PlanetTileEditorState } from '../exports.js';

// Represents the options for a <select> dropdown
type SelectOption = {
    label: string;
    value: string | number;
};

// The configuration for a single form field
type FieldConfig = {
    // The kind of input to render
    type: 'text' | 'number' | 'select' | 'checkbox' | 'command_button';
    // The property name in your state object
    key: string;
    // The UI label for the field
    label: string;
    // The current value of the field
    value: any;
    // Optional: is the field disabled?
    disabled?: boolean;
    // Optional: only for 'select' type
    options?: SelectOption[];
    // Callback to update persistent state
    onUpdate?: (key: string, value: any) => void;
    // Callback for one-shot commands
    onCommand?: (key: string, value: any) => void;
};


export class PlanetTileEditor {
    public readonly node: HTMLDivElement;

    private readonly fieldsContainer: HTMLDivElement;
    private readonly applyButton: HTMLButtonElement;

    // A copy of the last received editor state to send back on apply
    private lastReceivedState: PlanetTileEditorState | null = null;
    // A temporary store for one-shot commands like 'rotate' or 'size'
    private pendingCommands: { [key: string]: any } = {};

    constructor() {
        this.node = document.createElement('div');
        this.node.id = 'tile-editor';
        this.node.style.display = 'none'; // Initially hidden

        const title = document.createElement('h4');
        title.textContent = 'Tile Editor';
        this.node.appendChild(title);

        // A single container where the data-driven form will be rendered
        this.fieldsContainer = document.createElement('div');
        this.fieldsContainer.className = 'fields-container';
        this.node.appendChild(this.fieldsContainer);

        this.applyButton = document.createElement('button');
        this.applyButton.textContent = 'Apply Settings';
        this.applyButton.addEventListener('click', () => this.applySettings(false));
        this.node.appendChild(this.applyButton);
    }

    public show(): void {
        this.node.style.display = 'flex';
        this.node.style.flexDirection = 'column';
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

        // Define the entire form structure as a configuration object.
        // Adding, removing, or changing fields is now as simple as editing this array.
        const fields: FieldConfig[] = [
            // --- Selected Tile Properties ---
            {
                type: 'text',
                key: 'name',
                label: 'Name',
                value: state.name ?? '',
                onUpdate: (key, value) => {
                    if (this.lastReceivedState) this.lastReceivedState.name = value;
                },
            },
            {
                type: 'select',
                key: 'type',
                label: 'Terrain',
                value: state.terrain,
                options: state.terrainChoices.map((value, i) => ({
                    value: value,
                    label: value,
                })),
                onUpdate: (key, value) => {
                    if (this.lastReceivedState) this.lastReceivedState.terrain = value;
                },
            },
            {
                type: 'select',
                key: 'geology',
                label: 'Geology',
                value: state.geology,
                options: state.geologyChoices.map((value, i) => ({
                    value: value,
                    label: value,
                })),
                onUpdate: (key, value) => {
                    if (this.lastReceivedState) this.lastReceivedState.geology = value;
                },
            },
            // --- Global Grid Actions ---
            {
                type: 'number',
                key: 'size',
                label: 'Grid Size',
                value: state.size,
                disabled: !polar,
                onUpdate: (key, value) => this.pendingCommands[key] = value,
            },
            {
                type: 'command_button',
                key: 'rotate',
                label: 'Rotate Clockwise ↻',
                value: true, // Corresponds to 'cw' which Swift expects as 'true'
                disabled: !polar,
                onCommand: (key, value) => this.pendingCommands[key] = value,
            },
            {
                type: 'command_button',
                key: 'rotate',
                label: 'Rotate Counter-Clockwise ↺',
                value: false, // Corresponds to 'ccw' which Swift expects as 'false'
                disabled: !polar,
                onCommand: (key, value) => this.pendingCommands[key] = value,
            },
        ];

        this.renderForm(fields);
    }

    private renderForm(fields: FieldConfig[]): void {
        // Clear out the old fields to prevent duplicates
        this.fieldsContainer.innerHTML = '';
        const disabledTooltip: string = 'Select a polar tile to modify the grid.';

        for (const field of fields) {
            const fieldRow = document.createElement('div');
            fieldRow.className = 'editor-field-row';
            if (field.disabled) {
                fieldRow.title = disabledTooltip;
            }

            // Command buttons don't need a visible label, it's on the button itself
            if (field.type !== 'command_button') {
                const label = document.createElement('label');
                label.textContent = field.label;
                fieldRow.appendChild(label);
            }

            let inputElement: HTMLElement;

            switch (field.type) {
                case 'text':
                    inputElement = this.createTextInput(field);
                    break;
                case 'number':
                    inputElement = this.createNumberInput(field);
                    break;
                case 'select':
                    inputElement = this.createSelectInput(field);
                    break;
                case 'command_button':
                    inputElement = this.createCommandButton(field);
                    break;
                case 'checkbox':
                    inputElement = this.createCheckboxInput(field);
                    break;
            }

            fieldRow.appendChild(inputElement);
            this.fieldsContainer.appendChild(fieldRow);
        }
    }

    // --- Field Generator Functions ---

    private createTextInput(field: FieldConfig): HTMLInputElement {
        const input = document.createElement('input');
        input.type = 'text';
        input.value = field.value;
        input.disabled = field.disabled ?? false;
        if (field.onUpdate) {
            input.onchange = () => field.onUpdate!(field.key, input.value);
        }
        return input;
    }

    private createNumberInput(field: FieldConfig): HTMLInputElement {
        const input = document.createElement('input');
        input.type = 'number';
        input.value = field.value;
        input.min = "0";
        input.disabled = field.disabled ?? false;
        if (field.onUpdate) {
            input.onchange = () => field.onUpdate!(field.key, parseInt(input.value, 10));
        }
        return input;
    }

    private createSelectInput(field: FieldConfig): HTMLSelectElement {
        const select = document.createElement('select');
        select.disabled = field.disabled ?? false;

        for (const option of field.options ?? []) {
            const optElement = document.createElement('option');
            optElement.value = option.value.toString();
            optElement.textContent = option.label;
            if (option.value === field.value) {
                optElement.selected = true;
            }
            select.appendChild(optElement);
        }

        if (field.onUpdate) {
            select.onchange = () => field.onUpdate!(field.key, select.value);
        }
        return select;
    }

    private createCheckboxInput(field: FieldConfig): HTMLInputElement {
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.checked = field.value;
        input.disabled = field.disabled ?? false;
        if (field.onUpdate) {
            input.onchange = () => field.onUpdate!(field.key, input.checked);
        }
        return input;
    }

    private createCommandButton(field: FieldConfig): HTMLButtonElement {
        const button = document.createElement('button');
        button.textContent = field.label;
        button.disabled = field.disabled ?? false;

        button.onclick = () => {
            if (field.onCommand) {
                field.onCommand(field.key, field.value);
                // Immediately apply settings when a command button is clicked
                this.applySettings(true);
            }
        };
        return button;
    }

    private applySettings(isCommand: boolean): void {
        if (!this.lastReceivedState) return;

        // Start with the last known state, which includes any changes to persistent fields.
        const dataToSend = { ...this.lastReceivedState };

        // Merge any pending one-shot commands.
        // This will overwrite fields like `rotate` (which was null) with the command value.
        Object.assign(dataToSend, this.pendingCommands);

        // The name/type might have been updated via their own onUpdate handlers,
        // so we ensure they are correctly set from the last received state.
        dataToSend.name = this.lastReceivedState.name;
        dataToSend.terrain = this.lastReceivedState.terrain;
        dataToSend.geology = this.lastReceivedState.geology;


        Swift.loadTerrain(dataToSend);

        // IMPORTANT: Clear the pending commands immediately after sending.
        this.pendingCommands = {};

        // Give visual feedback to the user
        this.applyButton.textContent = 'Applied!';
        this.applyButton.style.backgroundColor = '#20d08d';
        setTimeout(() => {
            this.applyButton.textContent = 'Apply Settings';
            this.applyButton.style.backgroundColor = '';
        }, 1000);

        // If a command was issued (like rotate), we don't want to keep the editor open
        // as the state is now fundamentally changed.
        if (isCommand) {
             this.hide();
        }
    }
}
