@frozen public struct TradeProceeds {
    public let gain: Int64
    public let loss: Int64

    @inlinable public init(gain: Int64, loss: Int64) {
        self.gain = gain
        self.loss = loss
    }
}
extension TradeProceeds: AdditiveArithmetic {
    @inlinable public static var zero: Self {
        .init(gain: 0, loss: 0)
    }

    @inlinable public static func + (a: Self, b: Self) -> Self {
        .init(gain: a.gain + b.gain, loss: a.loss + b.loss)
    }
    @inlinable public static func - (a: Self, b: Self) -> Self {
        .init(gain: a.gain - b.gain, loss: a.loss - b.loss)
    }
}
