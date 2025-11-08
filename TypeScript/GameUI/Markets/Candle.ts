export interface Candle<Price> {
    readonly o: Price;
    readonly l: Price;
    readonly h: Price;
    readonly c: Price;
}
