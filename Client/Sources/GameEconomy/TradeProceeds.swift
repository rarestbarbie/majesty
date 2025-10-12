@frozen public struct TradeProceeds {
    public let gain: Int64
    public let loss: Int64

    @inlinable public init(gain: Int64, loss: Int64) {
        self.gain = gain
        self.loss = loss
    }
}
