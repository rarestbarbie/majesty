export interface ContextMenuItem {
    label: string;
    action?: string;
    arguments?: any[];
    disabled?: boolean;
    submenu?: ContextMenuItem[];
}
