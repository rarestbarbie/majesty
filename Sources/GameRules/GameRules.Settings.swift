import GameEconomy

extension GameRules {
    @frozen public struct Settings {
        public let exchange: BlocMarkets.Settings
    }
}
