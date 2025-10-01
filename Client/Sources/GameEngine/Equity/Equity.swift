import GameState
import JavaScriptInterop
import JavaScriptKit
import OrderedCollections
import Random

struct Equity<Owner> where Owner: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    var shares: OrderedDictionary<Owner, EquityStake<Owner>>
    var splits: [EquitySplit]

    init(shares: OrderedDictionary<Owner, EquityStake<Owner>>, splits: [EquitySplit] = []) {
        self.shares = shares
        self.splits = splits
    }
}
extension Equity: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) { self.init(shares: [:]) }
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
extension Equity {
    mutating func buyback(shares: Int64, from owner: Owner) {
        self.shares[owner, default: .init(id: owner)].buy(shares)
    }

    mutating func issue(shares: Int64, to owner: Owner) {
        self.shares[owner, default: .init(id: owner)].sell(shares)
    }

    mutating func turn() {
        var remove: [Int] = []
        for i: Int in self.shares.values.indices {
            {
                $0.turn()
                if $0.shares <= 0 {
                    remove.append(i)
                }
            } (&self.shares.values[i])
        }
        for i: Int in remove.reversed() {
            self.shares.remove(at: i)
        }
    }
}
extension Equity {
    @frozen public enum ObjectKey: JSString {
        case shares = "s"
        case splits = "p"
    }
}
extension Equity: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.shares] = self.shares
        js[.splits] = self.splits.isEmpty ? nil : self.splits
    }
}
extension Equity: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            shares: try js[.shares].decode(),
            splits: try js[.splits]?.decode() ?? []
        )
    }
}

#if TESTABLE
extension Equity: Equatable, Hashable {}
#endif
