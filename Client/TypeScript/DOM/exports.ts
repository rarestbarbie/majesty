export * from './Identifiable.js';
export * from './Sign.js';
export * from './Diffing/DiffableList.js';
export * from './Diffing/DiffableListElement.js';
export * from './Diffing/ManagedList.js';
export * from './Diffing/ManagedListElement.js';
export * from './Diffing/StaticList.js';
export * from './Filters/FilterList.js';
export * from './Filters/FilterTabs.js';
export * from './Menus/ContextMenu.js';
export * from './Menus/ContextMenuItem.js';
export * from './Menus/ContextMenuState.js';
export * from './Tooltips/CountInstruction.js';
export * from './Tooltips/ConditionLine.js';
export * from './Tooltips/ConditionListItem.js';
export * from './Tooltips/ConditionListInstruction.js';
export * from './Tooltips/FactorInstruction.js';
export * from './Tooltips/HeaderInstruction.js';
export * from './Tooltips/TickerInstruction.js';
export * from './Tooltips/Tooltip.js';
export * from './Tooltips/TooltipBreakdown.js';
export * from './Tooltips/TooltipInstruction.js';
export * from './Tooltips/TooltipInstructions.js';
export * from './Tooltips/TooltipInstructionType.js';
export * from './Tooltips/TooltipRenderer.js';

export * from './Fields/FieldList.js';
export * from './Fields/FieldListItem.js';
export * from './Fields/Fortune.js';
export * from './Fields/Count.js';
export * from './Fields/Ticker.js';

export function UpdateText(field: HTMLElement, value: string): void {
    if (field.textContent !== value) {
        field.textContent = value;
    }
}

export function UpdateBigInt(field: HTMLElement, value: bigint): void {
    UpdateText(field, value.toLocaleString());
}

export function UpdateDecimal(
    field: HTMLElement,
    value: number,
    places: number = 2
): void {
    if (value == 0) {
        UpdateText(field, '0');
        return;
    }

    const magnitude: string = value.toLocaleString(
        undefined,
        {
            minimumFractionDigits: places,
            maximumFractionDigits: places,
            signDisplay: 'never'
        }
    );
    if (value < 0) {
        UpdateText(field, `−${magnitude}`);
    } else {
        UpdateText(field, magnitude);
    }
}

export function UpdatePrice(
    field: HTMLElement,
    value: number,
    places: number = 2
): void {
    const magnitude: string = value.toLocaleString(
        undefined,
        {
            minimumFractionDigits: places,
            maximumFractionDigits: places,
            signDisplay: 'never'
        }
    );
    if (value < 0) {
        UpdateText(field, `−${magnitude}`);
    } else {
        UpdateText(field, magnitude);
    }
}
