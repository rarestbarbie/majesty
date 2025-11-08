export interface ContextMenuItem {
    label: string;
    action?: string;
    arguments?: any[];
    submenu?: ContextMenuItem[];
}
