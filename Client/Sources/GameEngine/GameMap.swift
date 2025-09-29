import Assert
import GameEconomy
import GameRules
import GameState
import OrderedCollections
import Random

struct GameMap: ~Copyable {
    var random: PseudoRandom
    var exchange: Exchange
    var notifications: Notifications

    var transfers: [LegalEntity: CashTransfers]
    var conversions: [(count: Int64, to: Pop.Section)]
    var jobs: (
        hire: (worker: Jobs.Hire<Address>, clerk: Jobs.Hire<PlanetID>),
        fire: (worker: Jobs.Fire, clerk: Jobs.Fire)
    )
    var localMarkets: LocalMarkets<PopID>
    var stockMarkets: StockMarkets<LegalEntity>

    init(
        date: GameDate,
        settings: GameRules.Settings,
        markets: OrderedDictionary<Market.AssetPair, Market> = [:]
    ) {
        self.random = .init(seed: 12345)
        self.exchange = .init(settings: settings.exchange, table: markets)
        self.notifications = .init(date: date)

        self.transfers = [:]
        self.conversions = []
        self.jobs = ((.init(), .init()), (.init(), .init()))
        self.localMarkets = .init()
        self.stockMarkets = .init()
    }
}
extension GameMap {
    var date: GameDate { self.notifications.date }
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

        // Occasionally the factory will receive a large windfall, and `quote(value:)` will
        // return a quantity that exceeds the number of shares in circulation!
        let shares: [Int64]? = recipients.distribute(share: \.shares) {
            // Cap the number of shares bought back at 1 percent of the total circulation.
            min($0 / 100, quote.quantity)
        }

        var compensationPaid: Int64 = 0

        if  let shares: [Int64],
            let compensation: [Int64] = shares.distribute(quote.cost) {
            for ((shares, compensation), recipient):
                ((Int64, Int64), EquityStake<LegalEntity>) in zip(
                    zip(shares, compensation),
                    recipients
                ) where shares > 0 {
                // Note that because of the way `distribute(share:funds:)` works, it’s possible
                // for `compensation` to be non-zero even while `shares` is zero. We ban this
                // situation manually here.
                equity.buyback(shares: shares, from: recipient.id)
                self.transfers[recipient.id, default: .init()].j += compensation
                compensationPaid += compensation
            }
        }

        #assert(
            compensationPaid <= quote.cost,
            "Compensation paid (\(compensationPaid)) exceeds cost quoted (\(quote.cost))!"
        )

        return compensationPaid
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
