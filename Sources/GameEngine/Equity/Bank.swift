import Assert
import Fraction
import GameEconomy
import GameIDs
import OrderedCollections
import Random

struct Bank {
    private(set) var accounts: OrderedDictionary<LEI, Account>

    init(accounts: OrderedDictionary<LEI, Account>) {
        self.accounts = accounts
    }
}
extension Bank {
    subscript(account id: LEI) -> Account {
        _read   { yield  self.accounts[id, default: .zero] }
        _modify { yield &self.accounts[id, default: .zero] }
    }
    subscript(account id: some LegalEntityIdentifier) -> Account {
        _read   { yield  self.accounts[id.lei, default: .zero] }
        _modify { yield &self.accounts[id.lei, default: .zero] }
    }
}
extension Bank {
    mutating func prune(in context: GameContext.PruningPass) {
        self.accounts.prune(unless: context.contains(_:))
    }
    mutating func turn() {
        self.accounts.update {
            $0.settle()
            return $0.balance != 0
        }
    }
}
extension Bank {
    mutating func transfer(
        budget: Int64,
        source: LEI,
        recipients: Turn.Payscale
    ) -> Int64 {
        guard let payments: [Int64] = recipients.split(limit: budget, share: \.owed) else {
            return 0
        }

        var paid: Int64 = 0

        for ((pop, _), payment): ((PopID, _), Int64) in zip(recipients, payments) {
            self[account: pop].i += payment
            paid += payment
        }

        #assert(
            0 ... budget ~= paid,
            "Payments (\(paid)) exceed budget (\(budget))!"
        )

        self[account: source].i -= paid
        return paid
    }

    mutating func transfer(
        budget: Int64,
        source: LEI,
        recipients shareholders: [EquityStake<LEI>]
    ) -> Int64 {
        guard
        let payments: [Int64] = shareholders.distribute(budget, share: \.shares.total) else {
            return 0
        }

        var paid: Int64 = 0

        for (shareholder, payment): (EquityStake<LEI>, Int64) in zip(shareholders, payments) {
            self[account: shareholder.id].i += payment
            paid += payment
        }

        #assert(
            budget == paid,
            "Dividends paid (\(paid)) does not equal dividend allocated (\(budget))!"
        )

        self[account: source].i -= paid
        return paid
    }
}
extension Bank {
    mutating func execute(
        trade fill: StockMarket.Fill,
        of equity: inout Equity<LEI>,
        at random: inout PseudoRandom
    ) {
        /// if the asset is not issuing enough shares to satisfy the order, buy some on the open
        /// market, which is essentially just a forced random liquidation
        let traded: Quote = equity.liquidate(at: &random, quote: fill.market) {
            self[account: $0].f += $1
        }

        equity.report(traded: traded.units)
        equity.assign(traded: traded.units, issued: fill.issued.units, to: fill.buyer)

        self[account: fill.buyer].e -= fill.issued.value + traded.value
        self[account: fill.asset].f += fill.issued.value
    }

    mutating func buyout(
        fraction: Double = 0.5,
        of security: LEI,
        as buyer: LEI,
        budget: Int64,
        equity: inout Equity<LEI>,
        random: inout PseudoRandom
    ) {
        if  fraction <= 0 {
            return
        }
        // compute number of shares that would have to be issued to make the buyer have
        // roughly `fraction` of the total shares after the buyout
        //
        // for numerical reasons, no more than 68 percent can be acquired at a time
        let fraction: Double = min(fraction, 0.68)
        let existing: Int64 = equity.shares.values.reduce(0) { $0 + $1.shares.total }
        let sharesToCreate: Int64 = .init(
            (Double.init(max(existing, 1)) * fraction / (1 - fraction)).rounded(.up)
        )

        equity.assign(traded: 0, issued: sharesToCreate, to: buyer)

        self[account: buyer].e -= budget
        self[account: security].f += budget
    }

    /// Returns the total compensation paid out to shareholders.
    mutating func buyback(
        security: StockMarket.Security,
        budget: Int64,
        equity: inout Equity<LEI>,
        random: inout PseudoRandom,
    ) -> Int64 {
        guard
        let quote: Quote = security.stockPrice?.quote(value: budget) else {
            return 0
        }
        let liquidated: Quote = equity.liquidate(at: &random, quote: quote, burn: true) {
            self[account: $0].f += $1
        }
        self[account: security.id].e -= liquidated.value
        return liquidated.value
    }
}
