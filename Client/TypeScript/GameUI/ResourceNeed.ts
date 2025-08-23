import { Resource } from './Resource.js';

export interface ResourceNeed {
    readonly id: Resource;
    readonly name: string;
    readonly icon: string;
    readonly tier: 'l' | 'e' | 'x';
    readonly acquired: bigint;
    readonly capacity: bigint;
    readonly demanded: bigint;
    readonly consumed: bigint;
    readonly purchased: bigint;
}
