import GameEconomy
import GameRules
import GameIDs
import OrderedCollections
import Random

struct GameWorld: ~Copyable {
    var random: PseudoRandom

    var notifications: Notifications
    var bank: Bank
    var segmentedMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
    var tradeableMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>
}
extension GameWorld {
    init(
        notifications: Notifications,
        bank: Bank,
        segmentedMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>,
        tradeableMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>,
        random: PseudoRandom,
    ) {
        self.random = random
        self.notifications = notifications
        self.bank = bank
        self.tradeableMarkets = tradeableMarkets
        self.segmentedMarkets = segmentedMarkets
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
                    table: self.segmentedMarkets
                ),
            )
        }
        _modify {
            var turn: Turn = self[settings]
            do {
                self = .init(
                    notifications: .init(date: .min),
                    bank: .init(accounts: [:]),
                    segmentedMarkets: [:],
                    tradeableMarkets: [:],
                    random: .init(seed: 0),
                )
            }
            defer {
                self = .init(
                    notifications: turn.notifications,
                    bank: turn.bank,
                    segmentedMarkets: turn.localMarkets.markets,
                    tradeableMarkets: turn.worldMarkets.markets,
                    random: turn.random,
                )
            }
            yield &turn
        }
    }
}
