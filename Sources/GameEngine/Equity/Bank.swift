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
    func valuation(
        of entity: some LegalEntityState,
        in context: GameContext.LegalPass,
    ) -> Equity<LEI>.Statistics {
        .compute(
            equity: entity.equity,
            // inventory, not assets, to avoid cratering stock price when expanding factory
            assets: self[account: entity.id.lei].balance + entity.z.vv,
            context: context
        )
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
            self[account: .pop(pop)].r += payment
            paid += payment
        }

        #assert(
            0 ... budget ~= paid,
            "Payments (\(paid)) exceed budget (\(budget))!"
        )

        self[account: source].b -= paid
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

        self[account: source].b -= paid
        return paid
    }

    /// Returns the total compensation paid out to shareholders.
    mutating func buyback(
        security: StockMarket.Security,
        budget: Int64,
        equity: inout Equity<LEI>,
        random: inout PseudoRandom,
    ) -> Int64 {
        guard let quote: StockPrice.Quote = security.stockPrice?.quote(value: budget) else {
            return 0
        }
        let liquidated: StockPrice.Quote = equity.liquidate(
            random: &random,
            quote: quote,
            burn: true
        ) {
            self[account: $0].j += $1
        }
        self[account: security.id].e -= liquidated.value
        return liquidated.value
    }
}
