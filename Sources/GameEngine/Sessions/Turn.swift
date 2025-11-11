import GameEconomy
import GameIDs
import Random

struct Turn: ~Copyable {
    var random: PseudoRandom
    var notifications: Notifications
    var worldMarkets: BlocMarkets
    var localMarkets: LocalMarkets
    var stockMarkets: StockMarkets

    var conversions: [Pop.Conversion]
    var bank: Bank
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
        worldMarkets: consuming BlocMarkets,
        localMarkets: consuming LocalMarkets,
    ) {
        self.random = random
        self.notifications = notifications
        self.worldMarkets = worldMarkets
        self.localMarkets = localMarkets
        self.stockMarkets = .init()
        self.conversions = []
        self.jobs = ((.init(), .init()), .init())
        self.bank = .init()
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
