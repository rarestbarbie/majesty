import GameEconomy
import GameRules
import GameIDs
import OrderedCollections
import Random

struct GameWorld: ~Copyable {
    var random: PseudoRandom
    var notifications: Notifications
    var tradeableMarkets: OrderedDictionary<BlocMarket.AssetPair, BlocMarket>
    var inelasticMarkets: OrderedDictionary<LocalMarkets.Key, LocalMarket>
}
extension GameWorld {
    init(
        notifications: Notifications,
        tradeableMarkets: OrderedDictionary<BlocMarket.AssetPair, BlocMarket>,
        inelasticMarkets: OrderedDictionary<LocalMarkets.Key, LocalMarket>,
        random: PseudoRandom,
    ) {
        self.random = random
        self.notifications = notifications
        self.tradeableMarkets = tradeableMarkets
        self.inelasticMarkets = inelasticMarkets
    }
}
extension GameWorld {
    var date: GameDate { self.notifications.date }
}
extension GameWorld {
    subscript(settings: GameRules.Settings) -> Turn {
        get {
            .init(
                random: self.random,
                notifications: self.notifications,
                worldMarkets: .init(
                    settings: settings.exchange,
                    table: self.tradeableMarkets
                ),
                localMarkets: .init(
                    table: self.inelasticMarkets
                )
            )
        }
        _modify {
            var turn: Turn = self[settings]
            do {
                self = .init(
                    notifications: .init(date: .min),
                    tradeableMarkets: [:],
                    inelasticMarkets: [:],
                    random: .init(seed: 0),
                )
            }
            defer {
                self = .init(
                    notifications: turn.notifications,
                    tradeableMarkets: turn.worldMarkets.markets,
                    inelasticMarkets: turn.localMarkets.markets,
                    random: turn.random,
                )
            }
            yield &turn
        }
    }
}
