import GameEconomy
import GameRules
import GameIDs
import OrderedCollections
import Random

struct GameWorld: ~Copyable {
    var random: PseudoRandom

    var notifications: Notifications
    var bank: Bank
    var tradeableMarkets: OrderedDictionary<BlocMarket.ID, BlocMarket>
    var inelasticMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
}
extension GameWorld {
    init(
        notifications: Notifications,
        bank: Bank,
        tradeableMarkets: OrderedDictionary<BlocMarket.ID, BlocMarket>,
        inelasticMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>,
        random: PseudoRandom,
    ) {
        self.random = random
        self.notifications = notifications
        self.bank = bank
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
                bank: self.bank,
                worldMarkets: .init(
                    settings: settings.exchange,
                    table: self.tradeableMarkets
                ),
                localMarkets: .init(
                    table: self.inelasticMarkets
                ),
            )
        }
        _modify {
            var turn: Turn = self[settings]
            do {
                self = .init(
                    notifications: .init(date: .min),
                    bank: .init(accounts: [:]),
                    tradeableMarkets: [:],
                    inelasticMarkets: [:],
                    random: .init(seed: 0),
                )
            }
            defer {
                self = .init(
                    notifications: turn.notifications,
                    bank: turn.bank,
                    tradeableMarkets: turn.worldMarkets.markets,
                    inelasticMarkets: turn.localMarkets.markets,
                    random: turn.random,
                )
            }
            yield &turn
        }
    }
}
