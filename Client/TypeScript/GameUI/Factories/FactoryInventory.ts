import { FactoryDetailsTab, ResourceNeed, ResourceSale } from '../exports.js';

export interface FactoryInventory {
    readonly type: FactoryDetailsTab.Inventory;
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
}
