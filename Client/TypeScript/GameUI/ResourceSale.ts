import { Resource } from './Resource.js';

export interface ResourceSale {
    readonly id: Resource;
    readonly name: string;
    readonly icon: string;
    readonly quantity: bigint;
    readonly leftover: bigint;
    readonly proceeds: bigint;
}
