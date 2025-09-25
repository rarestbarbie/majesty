import JavaScriptInterop
import JavaScriptKit
import OrderedCollections
import Random

struct Equity<Owner>
    where Owner: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    var shares: OrderedDictionary<Owner, EquityStake<Owner>>

    init(shares: OrderedDictionary<Owner, EquityStake<Owner>>) {
        self.shares = shares
    }
}
extension Equity: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) { self.init(shares: [:]) }
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
extension Equity: ConvertibleToJSArray {
    func encode(to js: inout JavaScriptEncoder<JavaScriptArrayKey>) {
        self.shares.encode(to: &js)
    }
}
extension Equity: LoadableFromJSArray {
    static func load(from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>) throws -> Self {
        self.init(shares: try .load(from: js))
    }
}

#if TESTABLE
extension Equity: Equatable, Hashable {}
#endif
