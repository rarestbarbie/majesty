import Fraction
import LiquidityPool

extension Exchange {
    @frozen public struct Settings {
        /// The fraction of the pool’s liquidity that will be drained each day. It is
        /// recommended to set this to no more than 0.5% of the transaction ``fee``.
        public let dividend: Fraction
        /// The transaction fee for using the exchange.
        public let fee: Fraction
        /// The initial liquidity for each market in the exchange.
        public let capital: LiquidityPool.Assets
        /// How many days of history to preserve for each market in the exchange.
        public let history: Int

        @inlinable public init(
            dividend: Fraction,
            fee: Fraction,
            capital: LiquidityPool.Assets,
            history: Int
        ) {
            self.dividend = dividend
            self.fee = fee
            self.capital = capital
            self.history = history
        }
    }
}
extension Exchange.Settings {
    @inlinable public static var `default`: Self {
        .init(
            dividend: 0 %/ 1,
            fee: 0 %/ 1,
            capital: .init(base: 2, quote: 2),
            history: 1,
        )
    }
}
extension Exchange.Settings {
    func new(_ pair: Market.AssetPair) -> Market {
        .init(
            id: pair,
            dividend: self.dividend,
            pool: .init(
                assets: .init(base: self.capital.base, quote: self.capital.quote),
                volume: .init(),
                fee: self.fee
            )
        )
    }
}
