import Assert
import GameEconomy
import GameIDs
import GameState
import JavaScriptInterop
import OrderedCollections
import Random

struct Equity<Owner> where Owner: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    private(set) var shares: OrderedDictionary<Owner, EquityStake<Owner>>
    // FIXME: consider capping the number of splits stored
    private(set) var splits: [EquitySplit]
    /// Total volume traded on the market today.
    private(set) var traded: Int64
    /// Total volume of shares issued today, negative if shares were burned.
    private(set) var issued: Int64

    init(
        shares: OrderedDictionary<Owner, EquityStake<Owner>>,
        splits: [EquitySplit] = [],
        traded: Int64 = 0,
        issued: Int64 = 0
    ) {
        self.shares = shares
        self.splits = splits
        self.traded = traded
        self.issued = issued
    }
}
extension Equity: Sendable where Owner: Sendable {}
extension Equity: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) { self.init(shares: [:]) }
}
extension Equity<LEI> {
    mutating func prune(in context: GameContext.PruningPass) {
        self.shares.prune(unless: context.contains(_:))
    }
    mutating func turn() {
        self.shares.update {
            $0.turn()
            return $0.shares.total > 0
        }
        self.traded = 0
        self.issued = 0
    }
}
extension Equity {
    private subscript(owner: Owner) -> EquityStake<Owner> {
        _read   { yield  self.shares[owner, default: .init(id: owner)] }
        _modify { yield &self.shares[owner, default: .init(id: owner)] }
    }
}
extension Equity {
    private mutating func split(_ split: EquitySplit) {
        switch split.factor {
        case .forward(let factor):
            for i: Int in self.shares.values.indices {
                self.shares.values[i].shares.untracked *= factor
            }
            if  case .forward? = self.splits.last?.factor {
                self.splits.append(split)
            } else {
                // clear history
                self.splits = [split]
            }

        case .reverse(let factor):
            for i: Int in self.shares.values.indices {
                self.shares.values[i].shares.untracked /= factor
            }
            if  case .reverse? = self.splits.last?.factor {
                self.splits.append(split)
            } else {
                self.splits = [split]
            }
        }
    }
}
extension Equity<LEI> {
    mutating func split(
        at price: Double,
        in country: CountryID,
        turn: inout Turn,
    ) {
        if  self.shares.isEmpty {
            self.splits = []
            self.issued += 1
            self[.reserve(country)].shares += 1
            return
        }

        // If today’s stock price is below 0.5, the stock will undergo a reverse split.
        // If above 4,000, it has a chance of undergoing a forward split. The higher the price,
        // the greater the chance.
        let split: EquitySplit

        if price > 4_000 {
            let chance: Int64

            if price > 100_000 {
                chance = 4
            } else if price > 50_000 {
                chance = 3
            } else if price > 20_000 {
                chance = 2
            } else {
                chance = 1
            }

            guard turn.random.roll(chance, 128) else {
                return
            }

            let exponent: Int64 = .random(in: 1 ... 3, using: &turn.random.generator)
            let factor: Int64 = 1 << exponent
            split = .forward(factor: factor, on: turn.date)

            turn.notifications[country] = """
            Stock split executed for factor of \(factor)x.
            """
        } else if price < 0.5 {
            let exponentRange: ClosedRange<Int64>
            let chance: Int64

            if  price < 0.1 {
                exponentRange = 3 ... 5
                chance = 3
            } else if price < 0.25 {
                exponentRange = 2 ... 3
                chance = 2
            } else {
                exponentRange = 1 ... 1
                chance = 1
            }

            guard turn.random.roll(chance, 128) else {
                return
            }

            let exponent: Int64 = .random(in: exponentRange, using: &turn.random.generator)
            let factor: Int64 = 1 << exponent
            split = .reverse(factor: factor, on: turn.date)

            turn.notifications[country] = """
            Reverse stock split executed for factor of \(factor)x.
            """
        } else {
            return
        }

        self.split(split)
    }
}
extension Equity<LEI> {
    mutating func trade(random: inout PseudoRandom, bank: inout Bank, fill: StockMarket.Fill) {
        let traded: StockPrice.Quote = self.liquidate(random: &random, quote: fill.market) {
            bank[account: $0].j += $1
        }

        self.traded += traded.quantity
        self.issued += fill.issued.quantity

        let quantity: Int64 = fill.issued.quantity + traded.quantity

        self[fill.buyer].shares += quantity

        bank[account: fill.buyer].e -= fill.issued.value + traded.value
        bank[account: fill.asset].e += fill.issued.value
    }

    mutating func liquidate(
        random: inout PseudoRandom,
        quote: StockPrice.Quote,
        burn: Bool = false,
        credit: (LEI, Int64) -> (),
    ) -> StockPrice.Quote {
        let recipients: [EquityStake<LEI>] = self.shares.values.shuffled(
            using: &random.generator
        )

        // Occasionally the factory will receive a large windfall, and `quote(value:)` will
        // return a quantity that exceeds the number of shares in circulation!
        let shares: [Int64]? = recipients.distribute(share: \.shares.total) {
            // Cap the number of shares bought back at 1 percent of the total circulation,
            // but always allow at least one share to be bought back
            min(max(1, $0 / 100), quote.quantity)
        }

        var liquidated: StockPrice.Quote = .init(quantity: 0, value: 0)

        if  let shares: [Int64],
            let compensation: [Int64] = shares.distribute(quote.value) {
            for ((shares, compensation), recipient): ((Int64, Int64), EquityStake<LEI>) in zip(
                    zip(shares, compensation),
                    recipients
                ) where shares > 0 {
                // Note that because of the way `distribute(share:funds:)` works, it’s possible
                // for `compensation` to be non-zero even while `shares` is zero. We ban this
                // situation manually here.
                self[recipient.id].shares -= shares


                liquidated.quantity += shares
                liquidated.value += compensation
                credit(recipient.id, compensation)
            }
        }

        if  burn {
            self.issued -= liquidated.quantity
        }

        #assert(
            liquidated.value <= quote.value,
            "Compensation paid (\(liquidated.value)) exceeds cost quoted (\(quote.value))!"
        )

        return liquidated
    }
}
extension Equity {
    @frozen public enum ObjectKey: JSString {
        case shares = "s"
        case splits = "p"
        case traded = "t"
        case issued = "i"
    }
}
extension Equity: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.shares] = self.shares
        js[.splits] = self.splits.isEmpty ? nil : self.splits
        js[.traded] = self.traded == 0 ? nil : self.traded
        js[.issued] = self.issued == 0 ? nil : self.issued
    }
}
extension Equity: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            shares: try js[.shares].decode(),
            splits: try js[.splits]?.decode() ?? [],
            traded: try js[.traded]?.decode() ?? 0,
            issued: try js[.issued]?.decode() ?? 0,
        )
    }
}

#if TESTABLE
extension Equity: Equatable {}
#endif
