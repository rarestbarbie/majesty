import Assert
import GameEconomy
import GameRules
import GameState
import Random
import OrderedCollections

struct GameMap: ~Copyable {
    var random: PseudoRandom

    var exchange: Exchange
    var transfers: [LegalEntity: CashTransfers]
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
    /// Returns the total compensation paid out to shareholders.
    mutating func buyback(
        value: Int64,
        from equity: inout Equity<LegalEntity>,
        of security: StockMarket<LegalEntity>.Security,
        in currency: Fiat,
    ) -> Int64 {
        let quote: (quantity: Int64, cost: Int64) = security.quote(value: value)

        guard quote.quantity > 0, quote.cost > 0 else {
            return 0
        }

        let recipients: [EquityStake<LegalEntity>] = equity.shares.values.shuffled(
            using: &self.random.generator
        )

        guard
        let shares: [Int64] = recipients.distribute(quote.quantity, share: \.shares),
        let compensation: [Int64] = shares.distribute(quote.cost) else {
            // If nobody owns shares, nothing to do.
            return 0
        }

        for ((shares, compensation), recipient):
            ((Int64, Int64), EquityStake<LegalEntity>) in zip(
            zip(shares, compensation),
            recipients
        ) {
            equity.buyback(shares: shares, from: recipient.id)
            self.transfers[recipient.id, default: .init()].j += compensation
        }

        return quote.cost
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
            self.transfers[.pop(pop), default: .init()].c += payment
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
            self.transfers[.pop(pop), default: .init()].w += payment
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
        to shareholders: [EquityStake<LegalEntity>]
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
            self.transfers[shareholder.id, default: .init()].i += payment
            dividendsPaid += payment
        }

        #assert(
            dividend == dividendsPaid,
            "Dividends paid (\(dividendsPaid)) does not equal dividend allocated (\(dividend))!"
        )

        return dividendsPaid
    }
}
