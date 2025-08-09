export interface FactoryWorkers {
    readonly type: string;
    readonly limit: bigint;
    readonly union: bigint;
    readonly striking: bigint;
    readonly nonunion: bigint;
    readonly hire: bigint;
    readonly fire: bigint;
    readonly quit: bigint;
}
