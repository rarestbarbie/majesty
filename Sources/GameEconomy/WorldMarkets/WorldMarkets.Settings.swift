import Assert
import D
import Fraction
import LiquidityPool
import OrderedCollections

extension WorldMarkets {
    @frozen public struct Settings {
        public let depth: Decimal
        public let rot: Decimal
        /// The transaction fee for using the exchange.
        public let fee: Decimal
        public let feeBoundary: Double
        public let feeSchedule: Double
        /// The initial liquidity for each market in the exchange.
        public let capital: LiquidityPool.Assets
        /// How many days of history to preserve for each market in the exchange.
        public let history: Int

        public init(
            depth: Decimal,
            rot: Decimal,
            fee: Decimal,
            feeBoundary: Double,
            feeSchedule: Double,
            capital: LiquidityPool.Assets,
            history: Int
        ) {
            self.depth = depth
            self.rot = rot
            self.fee = fee
            self.feeBoundary = feeBoundary
            self.feeSchedule = feeSchedule
            self.capital = capital
            self.history = history

            #assert(self.feeBoundary > 0, "Fee boundary must be positive!!!")
            #assert(self.shape.fee(velocity: 1) < 1, "Maximum fee must be less than 100%!!!")
        }
    }
}
extension WorldMarkets.Settings {
    var shape: WorldMarket.Shape {
        .init(
            depth: Double.init(self.depth),
            rot: self.rot,
            fee: self.fee,
            feeBoundary: self.feeBoundary,
            feeSchedule: self.feeSchedule
        )
    }
}
extension WorldMarkets.Settings {
    func new(_ pair: WorldMarket.ID) -> WorldMarket {
        let initial: WorldMarket.Interval = .init(
            assets: self.capital,
            fee: 0,
            indicators: .compute(from: self.capital))
        let state: WorldMarket.State = .init(
            id: pair,
            history: [],
            y: initial,
            z: initial,
        )
        return self.load(state)
    }

    func load(_ state: WorldMarket.State) -> WorldMarket {
        .init(state: state, shape: self.shape)
    }

    public func load(
        _ markets: [WorldMarket.State]
    ) -> OrderedDictionary<WorldMarket.ID, WorldMarket> {
        markets.reduce(
            into: .init(minimumCapacity: markets.count)) {
            $0[$1.id] = self.load($1)
        }
    }
}
