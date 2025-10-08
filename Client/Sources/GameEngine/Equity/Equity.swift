import Assert
import GameState
import JavaScriptInterop
import JavaScriptKit
import OrderedCollections
import Random

struct Equity<Owner> where Owner: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    private(set) var shares: OrderedDictionary<Owner, EquityStake<Owner>>
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
extension Equity: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) { self.init(shares: [:]) }
}
extension Equity<LEI> {
    mutating func prune(in context: GameContext.PruningPass) {
        self.shares.update {
            if $0.shares <= 0 {
                return false
            }
            switch $0.id {
            case .factory(let id):
                return context.factories.contains(id)
            case .pop(let id):
                return context.pops.contains(id)
            }
        }
    }
    mutating func turn() {
        for i: Int in self.shares.values.indices {
            self.shares.values[i].turn()
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
                self.shares.values[i].shares *= factor
            }
        case .reverse(let factor):
            for i: Int in self.shares.values.indices {
                self.shares.values[i].shares /= factor
            }
        }

        self.splits.append(split)
    }

    mutating func split(
        price: Double,
        map: inout GameMap,
        notifying subscribers: [CountryID]
    ) {
        if self.shares.isEmpty {
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

            guard map.random.roll(chance, 128) else {
                return
            }

            let exponent: Int64 = .random(in: 1 ... 3, using: &map.random.generator)
            let factor: Int64 = 1 << exponent
            split = .forward(factor: factor, on: map.date)

            map.notifications[subscribers] = """
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

            guard map.random.roll(chance, 128) else {
                return
            }

            let exponent: Int64 = .random(in: exponentRange, using: &map.random.generator)
            let factor: Int64 = 1 << exponent
            split = .reverse(factor: factor, on: map.date)

            map.notifications[subscribers] = """
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
        let traded: StockPrice.Quote = self.liquidate(
            random: &random,
            bank: &bank,
            quote: fill.market
        )

        self.traded += traded.quantity
        self.issued += fill.issued.quantity

        let quantity: Int64 = fill.issued.quantity + traded.quantity

        ; {
            $0.shares += quantity
            $0.bought += quantity
        } (&self[fill.buyer])

        bank[fill.buyer].e -= fill.issued.value + traded.value
        bank[fill.asset].e += fill.issued.value
    }

    mutating func liquidate(
        random: inout PseudoRandom,
        bank: inout Bank,
        quote: StockPrice.Quote,
        burn: Bool = false
    ) -> StockPrice.Quote {
        let recipients: [EquityStake<LEI>] = self.shares.values.shuffled(
            using: &random.generator
        )

        // Occasionally the factory will receive a large windfall, and `quote(value:)` will
        // return a quantity that exceeds the number of shares in circulation!
        let shares: [Int64]? = recipients.distribute(share: \.shares) {
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
                {
                    $0.shares -= shares
                    $0.sold += shares
                } (&self[recipient.id])


                liquidated.quantity += shares
                liquidated.value += compensation
                bank[recipient.id].j += compensation
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
extension Equity: Equatable, Hashable {}
#endif
