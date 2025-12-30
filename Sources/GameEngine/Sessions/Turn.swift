import GameEconomy
import GameIDs
import Random
import OrderedCollections

struct Turn: ~Copyable {
    var random: PseudoRandom
    var notifications: Notifications
    var bank: Bank
    var worldMarkets: WorldMarkets
    var localMarkets: LocalMarkets
    var tradeRoutes: OrderedDictionary<CurrencyID, TradeRoutes>
    var stockMarkets: StockMarkets

    var conversions: [Pop.Conversion]
    var jobs: (
        hire: (
            planet: LaborMarket.Demand<LaborMarket.Planetwide>,
            region: LaborMarket.Demand<LaborMarket.Regionwide>
        ),
        fire: Jobs.Fire
    )
}
extension Turn {
    init(
        random: PseudoRandom,
        notifications: Notifications,
        bank: consuming Bank,
        worldMarkets: consuming WorldMarkets,
        localMarkets: consuming LocalMarkets,
        tradeRoutes: OrderedDictionary<CurrencyID, TradeRoutes>,
    ) {
        self.random = random
        self.notifications = notifications
        self.bank = bank
        self.worldMarkets = worldMarkets
        self.localMarkets = localMarkets
        self.tradeRoutes = tradeRoutes
        self.stockMarkets = .init()
        self.conversions = []
        self.jobs = (([:], [:]), .init())
    }
}

extension Turn {
    var date: GameDate { self.notifications.date }
}
extension Turn {
    mutating func payscale(
        shuffling pops: [(id: PopID, count: Int64)],
        rate: Int64
    ) -> Payscale {
        .init(pops: pops.shuffled(using: &self.random.generator), rate: rate)
    }
}
