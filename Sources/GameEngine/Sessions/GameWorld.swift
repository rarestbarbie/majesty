import GameEconomy
import GameRules
import GameIDs
import OrderedCollections
import Random

struct GameWorld: ~Copyable {
    var random: PseudoRandom

    var notifications: Notifications
    var bank: Bank
    var localMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
    var worldMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>
    var tradeRoutes: OrderedDictionary<CurrencyID, TradeRoutes>
}
extension GameWorld {
    init(
        notifications: Notifications,
        bank: Bank,
        localMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>,
        worldMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>,
        tradeRoutes: OrderedDictionary<CurrencyID, TradeRoutes>,
        random: PseudoRandom,
    ) {
        self.random = random
        self.notifications = notifications
        self.bank = bank
        self.worldMarkets = worldMarkets
        self.localMarkets = localMarkets
        self.tradeRoutes = tradeRoutes
    }
}
extension GameWorld {
    var date: GameDate { self.notifications.date }
}
extension GameWorld {
    subscript(settings: GameMetadata.Settings) -> Turn {
        get {
            .init(
                random: self.random,
                notifications: self.notifications,
                bank: self.bank,
                worldMarkets: .init(
                    settings: settings.exchange,
                    table: self.worldMarkets
                ),
                localMarkets: .init(
                    table: self.localMarkets
                ),
                tradeRoutes: self.tradeRoutes
            )
        }
        _modify {
            var turn: Turn = self[settings]
            do {
                self = .init(
                    notifications: .init(date: .min),
                    bank: .init(accounts: [:]),
                    localMarkets: [:],
                    worldMarkets: [:],
                    tradeRoutes: [:],
                    random: .init(seed: 0),
                )
            }
            defer {
                self = .init(
                    notifications: turn.notifications,
                    bank: turn.bank,
                    localMarkets: turn.localMarkets.all,
                    worldMarkets: turn.worldMarkets.all,
                    tradeRoutes: turn.tradeRoutes,
                    random: turn.random,
                )
            }
            yield &turn
        }
    }
}
