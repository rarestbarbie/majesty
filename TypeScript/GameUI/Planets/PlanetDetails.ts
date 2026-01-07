import { TermState } from '../../DOM/exports.js';

export interface PlanetDetails {
    readonly id: string;
    readonly open: string;
    readonly name?: string;
    readonly terms: TermState[];
}
