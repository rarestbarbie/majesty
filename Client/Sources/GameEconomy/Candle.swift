@frozen public struct Candle<Price> where Price: Comparable {
    public let o: Price
    public var l: Price
    public var h: Price
    public var c: Price

    @inlinable public init(o: Price, l: Price, h: Price, c: Price) {
        self.o = o
        self.l = l
        self.h = h
        self.c = c
    }
}
extension Candle {
    @inlinable public static func open(_ price: Price) -> Self {
        .init(o: price, l: price, h: price, c: price)
    }

    @inlinable public mutating func update(_ price: Price) {
        self.h = max(self.h, price)
        self.l = min(self.l, price)
        self.c = price
    }
}
