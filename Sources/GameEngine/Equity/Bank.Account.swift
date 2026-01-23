import Assert
import Fraction
import GameEconomy
import JavaScriptInterop

extension Bank {
    struct Account: Equatable, Sendable {
        var settled: Int64

        /// Spending, excluding equity purchases. Negative if funds are spent.
        var b: Int64

        /// Income.
        var r: Int64
        /// Subsidies.
        var s: Int64

        /// Interest and dividends, positive for income, unset if paid out (counted in ``b``).
        var i: Int64
        /// Proceeds from stock sales. Not to be confused with ``e``.
        var j: Int64
        /// Equity value, negative for purchasers of equity, positive for issuers.
        var e: Int64

        /// Inheritance, from members leaving or joining a pop.
        var d: Int64
    }
}
extension Bank.Account {
    init(settled: Int64) {
        self.init(settled: settled, b: 0, r: 0, s: 0, i: 0, j: 0, e: 0, d: 0)
    }
    static var zero: Self {
        .init(settled: 0, b: 0, r: 0, s: 0, i: 0, j: 0, e: 0, d: 0)
    }
}
extension Bank.Account {
    static func += (self: inout Self, trade: TradeProceeds) {
        self.b += trade.loss
        self.r += trade.gain
    }
}
extension Bank.Account {
    var Δ: Delta<Int64> {
        .init(y: self.settled, z: self.balance)
    }

    var balance: Int64 {
        self.settled +
        self.b +
        self.r +
        self.s +
        self.i +
        self.j +
        self.e +
        self.d
    }

    mutating func settle() {
        self.settled += self.b; self.b = 0
        self.settled += self.r; self.r = 0
        self.settled += self.s; self.s = 0
        self.settled += self.i; self.i = 0
        self.settled += self.j; self.j = 0
        self.settled += self.e; self.e = 0
        self.settled += self.d; self.d = 0
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
        case settled = "X"
        case b
        case r
        case s
        case i
        case j
        case e
        case d
    }
}
extension Bank.Account: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.settled] = self.settled
        js[.b] = self.b
        js[.r] = self.r
        js[.s] = self.s
        js[.i] = self.i
        js[.j] = self.j
        js[.e] = self.e
        js[.d] = self.d
    }
}
extension Bank.Account: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            settled: try js[.settled].decode(),
            b: try js[.b]?.decode() ?? 0,
            r: try js[.r]?.decode() ?? 0,
            s: try js[.s]?.decode() ?? 0,
            i: try js[.i]?.decode() ?? 0,
            j: try js[.j]?.decode() ?? 0,
            e: try js[.e]?.decode() ?? 0,
            d: try js[.d]?.decode() ?? 0
        )
    }
}
