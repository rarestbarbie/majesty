import GameEconomy
import GameIDs
import Random

struct Turn: ~Copyable {
    var random: PseudoRandom
    var notifications: Notifications
    var bank: Bank
    var worldMarkets: WorldMarkets
    var localMarkets: LocalMarkets
    var stockMarkets: StockMarkets

    var conversions: [Pop.Conversion]
    var jobs: (
        hire: (
            remote: Jobs.Hire<PlanetID>,
            local: Jobs.Hire<Address>
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
    ) {
        self.random = random
        self.notifications = notifications
        self.bank = bank
        self.worldMarkets = worldMarkets
        self.localMarkets = localMarkets
        self.stockMarkets = .init()
        self.conversions = []
        self.jobs = ((.init(), .init()), .init())
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
