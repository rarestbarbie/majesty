import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

struct Equity<Owner>
    where Owner: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    var shares: OrderedDictionary<Owner, Property<Owner>>

    init(shares: OrderedDictionary<Owner, Property<Owner>>) {
        self.shares = shares
    }
}
extension Equity {
    mutating func issue(shares: Int64, to owner: Owner) {
        self.shares[owner, default: .init(id: owner)].sell(shares)
    }
    mutating func buyback(shares: Int64, from owner: Owner) {
        self.shares[owner, default: .init(id: owner)].buy(shares)
    }
}
extension Equity: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) { self.init(shares: [:]) }
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
