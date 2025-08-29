extension LiquidityPool.Volume {
    @frozen public struct Side {
        //public var fees: Int64
        public var i: Int64
        public var o: Int64

        @inlinable public init(
            //fees: Int64 = 0,
            i: Int64 = 0,
            o: Int64 = 0
        ) {
            //self.fees = fees
            self.i = i
            self.o = o
        }
    }
}
extension LiquidityPool.Volume.Side {
    @inlinable public var total: Int64 { self.i + self.o }

    @inlinable mutating func reset() {
        //self.fees = 0
        self.i = 0
        self.o = 0
    }
}
