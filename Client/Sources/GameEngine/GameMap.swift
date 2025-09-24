import Assert
import GameEconomy
import GameRules
import GameState
import Random
import OrderedCollections

struct GameMap: ~Copyable {
    var random: PseudoRandom

    var exchange: Exchange
    var transfers: [PopID: CashTransfers]
    var conversions: [(count: Int64, to: Pop.Section)]
    var jobs: (
        hire: (worker: Jobs.Hire<Address>, clerk: Jobs.Hire<PlanetID>),
        fire: (worker: Jobs.Fire, clerk: Jobs.Fire)
    )
    var localMarkets: LocalMarkets<PopID>
    var stockMarkets: StockMarkets<LegalEntity>

    init(
        settings: GameRules.Settings,
        markets: OrderedDictionary<Market.AssetPair, Market> = [:]
    ) {
        self.random = .init(seed: 12345)

        self.exchange = .init(settings: settings.exchange, table: markets)
        self.transfers = [:]
        self.conversions = []
        self.jobs = ((.init(), .init()), (.init(), .init()))
        self.localMarkets = .init()
        self.stockMarkets = .init()
    }
}
extension GameMap {
    mutating func payscale(
        shuffling pops: [(id: PopID, count: Int64)],
        rate: Int64
    ) -> Payscale {
        .init(pops: pops.shuffled(using: &self.random.generator), rate: rate)
    }

    mutating func pay(salariesBudget: Int64, salaries recipients: [Payscale]) -> Int64 {
        guard let payments: [Int64] = recipients.joined().split(
            limit: salariesBudget,
            share: \.owed
        ) else {
            return 0
        }

        var salariesPaid: Int64 = 0

        for ((pop, _), payment) in zip(recipients.joined(), payments) {
            self.transfers[pop, default: .init()].c += payment
            salariesPaid += payment
        }

        return salariesPaid
    }

    mutating func pay(wagesBudget: Int64, wages recipients: Payscale) -> Int64 {
        guard let payments: [Int64] = recipients.split(limit: wagesBudget, share: \.owed) else {
            return 0
        }

        var wagesPaid: Int64 = 0

        for ((pop, _), payment) in zip(recipients, payments) {
            self.transfers[pop, default: .init()].w += payment
            wagesPaid += payment
        }

        #assert(
            0 ... wagesBudget ~= wagesPaid,
            "Wages paid (\(wagesPaid)) exceeds budget (\(wagesBudget))!"
        )

        return wagesPaid
    }

    mutating func pay(
        dividend: Int64,
        to shareholders: [Property<LegalEntity>]
    ) -> Int64 {
        guard
        let payments: [Int64] = shareholders.distribute(
            dividend,
            share: \.shares
        ) else {
            return 0
        }

        var dividendsPaid: Int64 = 0

        for (shareholder, payment) in zip(shareholders, payments) {
            switch shareholder.id {
            case .pop(let id):
                self.transfers[id, default: .init()].i += payment
            case .factory:
                fatalError("unimplemented")
            }
            dividendsPaid += payment
        }

        #assert(
            dividend == dividendsPaid,
            "Dividends paid (\(dividendsPaid)) does not equal dividend allocated (\(dividend))!"
        )

        return dividendsPaid
    }
}
