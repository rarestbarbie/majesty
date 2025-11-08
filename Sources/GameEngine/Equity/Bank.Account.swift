import Assert
import Fraction
import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension Bank {
    struct Account {
        var liq: Int64

        /// Credit balance, negative if debt is owed.
        var b: Int64
        var v: Int64

        /// Revenue.
        var r: Int64
        /// Subsidies.
        var s: Int64
        /// Salaries, negative if salaries are owed.
        var c: Int64
        /// Wages, negative if wages are owed.
        var w: Int64

        /// Interest and dividends, negative if owed.
        var i: Int64
        /// Equity value, negative for purchasers of equity, positive for issuers.
        var e: Int64

        /// Inheritance, from members leaving or joining a pop.
        var d: Int64
    }
}
extension Bank.Account {
    init(liq: Int64) {
        self.init(liq: liq, b: 0, v: 0, r: 0, s: 0, c: 0, w: 0, i: 0, e: 0, d: 0)
    }
    init() {
        self.init(liq: 0, b: 0, v: 0, r: 0, s: 0, c: 0, w: 0, i: 0, e: 0, d: 0)
    }
}
extension Bank.Account {
    static func += (self: inout Self, other: Bank.Transfers) {
        self.s += other.s
        self.c += other.c
        self.w += other.w
        self.i += other.i
        self.e += other.e
        self.v += other.j
    }
    static func += (self: inout Self, trade: TradeProceeds) {
        self.b += trade.loss
        self.r += trade.gain
    }
    static func += (self: inout Self, other: Self) {
        self = .init(
            liq: self.liq + other.liq,
            b: self.b + other.b,
            v: self.v + other.v,
            r: self.r + other.r,
            s: self.s + other.s,
            c: self.c + other.c,
            w: self.w + other.w,
            i: self.i + other.i,
            e: self.e + other.e,
            d: self.d + other.d
        )
    }
}
extension Bank.Account {
    var balance: Int64 {
        self.liq +
        self.b +
        self.v +
        self.r +
        self.s +
        self.c +
        self.w +
        self.i +
        self.e +
        self.d
    }

    mutating func settle() {
        self.liq += self.b; self.b = 0
        self.liq += self.v; self.v = 0
        self.liq += self.r; self.r = 0
        self.liq += self.s; self.s = 0
        self.liq += self.c; self.c = 0
        self.liq += self.w; self.w = 0
        self.liq += self.i; self.i = 0
        self.liq += self.e; self.e = 0
        self.liq += self.d; self.d = 0
    }

    mutating func inherit(fraction: Fraction) -> Int64 {
        guard fraction.n > 0 else {
            return 0
        }

        let inherited: Int64

        if fraction.n < fraction.d {
            inherited = self.balance <> fraction
        } else {
            inherited = self.balance
        }

        self.d -= inherited
        return inherited
    }
}
extension Bank.Account {
    enum ObjectKey: JSString, Sendable {
        case liq
        case b
        case v
        case r
        case s
        case c
        case w
        case i
        case e
        case d
    }
}
extension Bank.Account: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.liq] = self.liq
        js[.b] = self.b
        js[.v] = self.v
        js[.r] = self.r
        js[.s] = self.s
        js[.c] = self.c
        js[.w] = self.w
        js[.i] = self.i
        js[.e] = self.e
        js[.d] = self.d
    }
}
extension Bank.Account: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            liq: try js[.liq].decode(),
            b: try js[.b]?.decode() ?? 0,
            v: try js[.v]?.decode() ?? 0,
            r: try js[.r]?.decode() ?? 0,
            s: try js[.s]?.decode() ?? 0,
            c: try js[.c]?.decode() ?? 0,
            w: try js[.w]?.decode() ?? 0,
            i: try js[.i]?.decode() ?? 0,
            e: try js[.e]?.decode() ?? 0,
            d: try js[.d]?.decode() ?? 0
        )
    }
}

#if TESTABLE
extension Bank.Account: Equatable, Hashable {}
#endif
