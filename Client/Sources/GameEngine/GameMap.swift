import GameEconomy
import GameRules
import GameIDs
import OrderedCollections
import Random

struct GameMap: ~Copyable {
    var random: PseudoRandom
    var exchange: Exchange
    var notifications: Notifications

    var conversions: [Pop.Conversion]
    var jobs: (
        hire: (worker: Jobs.Hire<Address>, clerk: Jobs.Hire<PlanetID>),
        fire: (worker: Jobs.Fire, clerk: Jobs.Fire)
    )
    var localMarkets: LocalMarkets
    var stockMarkets: StockMarkets
    var bank: Bank

    init(
        date: GameDate,
        settings: GameRules.Settings,
        markets: OrderedDictionary<Market.AssetPair, Market> = [:]
    ) {
        self.random = .init(seed: 12345)
        self.exchange = .init(settings: settings.exchange, table: markets)
        self.notifications = .init(date: date)

        self.conversions = []
        self.jobs = ((.init(), .init()), (.init(), .init()))
        self.localMarkets = .init()
        self.stockMarkets = .init()
        self.bank = .init()
    }
}
extension GameMap {
    var date: GameDate { self.notifications.date }
}
extension GameMap {
    mutating func payscale(
        shuffling pops: [(id: PopID, count: Int64)],
        rate: Int64
    ) -> Payscale {
        .init(pops: pops.shuffled(using: &self.random.generator), rate: rate)
    }
}
