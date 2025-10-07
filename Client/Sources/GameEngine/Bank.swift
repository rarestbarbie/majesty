import Assert
import GameEconomy
import GameState
import Random

struct Bank: ~Copyable {
    private var transfers: [LEI: CashTransfers]

    init() {
        self.transfers = [:]
    }
}
extension Bank {
    subscript(id: LEI) -> CashTransfers {
        _read   { yield  self.transfers[id, default: .init()] }
        _modify { yield &self.transfers[id, default: .init()] }
    }
}
extension Bank {
    mutating func turn(_ yield: (LEI, CashTransfers) -> ()) {
        defer {
            self.transfers.removeAll(keepingCapacity: true)
        }
        for (id, transfers): (LEI, CashTransfers) in self.transfers {
            yield(id, transfers)
        }
    }
}
extension Bank {
    /// Returns the total compensation paid out to shareholders.
    mutating func buyback(
        random: inout PseudoRandom,
        equity: inout Equity<LEI>,
        budget value: Int64,
        security: StockMarket.Security,
    ) -> Int64 {
        guard let quote: StockPrice.Quote = security.stockPrice?.quote(value: value) else {
            return 0
        }
        let liquidated: StockPrice.Quote = equity.liquidate(random: &random, bank: &self, quote: quote, burn: true)
        return liquidated.value
    }
}
extension Bank {
    mutating func pay(salariesBudget: Int64, salaries recipients: [GameMap.Payscale]) -> Int64 {
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

    mutating func pay(wagesBudget: Int64, wages recipients: GameMap.Payscale) -> Int64 {
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
        to shareholders: [EquityStake<LEI>]
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
