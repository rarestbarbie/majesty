import Assert
import Fraction
import GameEconomy
import GameUI
import JavaScriptInterop

extension Bank {
    struct Account: Equatable, Sendable {
        var settled: Int64

        /// Spending, excluding equity purchases. Negative if funds are spent.
        ///
        /// This is the negative complement of ``r``, and is a type of capital gains.
        var b: Int64
        /// Proceeds, excluding equity sales. Positive if funds are received.
        ///
        /// This is the positive complement of ``b``, and is a type of capital gains.
        ///
        /// Income is not computed from `r`, instead, income is recorded at the time of
        /// production, and the difference between the mark-to-market value of goods and the
        /// actual revenue received constitutes a capital gain or loss.
        var c: Int64

        /// Inheritance, from members leaving or joining a pop.
        var d: Int64

        /// Spending on equity purchases. Negative if funds are spent.
        ///
        /// This is the negative complement of ``f``.
        var e: Int64
        /// Proceeds from equity sales. Positive if funds are received.
        ///
        /// This is the positive complement of ``e``.
        var f: Int64

        /// Regular Income.
        ///
        /// This is usually stable over time, and includes income from sources such as:
        /// -   Paychecks
        /// -   Interest and dividends
        ///
        /// For pops, this is positive, for factories, this is negative, and represents
        /// paychecks paid to employees and dividends (but not buybacks) paid to shareholders.
        ///
        /// To get total income, `s` and the illiquid `valueAdded` must be added to this.
        var i: Int64
        /// Subsidies.
        var s: Int64
    }
}
extension Bank.Account {
    init(settled: Int64) {
        self.init(
            settled: settled,
            b: 0,
            c: 0,
            d: 0,
            e: 0,
            f: 0,
            i: 0,
            s: 0,
        )
    }
    static var zero: Self {
        .init(settled: 0)
    }
}
extension Bank.Account {
    static func += (self: inout Self, trade: TradeProceeds) {
        self.b += trade.loss
        self.c += trade.gain
    }
}
extension Bank.Account {
    var Δ: Delta<Int64> {
        .init(y: self.settled, z: self.balance)
    }

    var balance: Int64 {
        self.settled +
        self.b +
        self.c +
        self.d +
        self.e +
        self.f +
        self.i +
        self.s
    }

    mutating func settle() {
        self.settled += self.b; self.b = 0
        self.settled += self.c; self.c = 0
        self.settled += self.d; self.d = 0
        self.settled += self.e; self.e = 0
        self.settled += self.f; self.f = 0
        self.settled += self.i; self.i = 0
        self.settled += self.s; self.s = 0
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
        case c
        case d
        case e
        case f
        case i
        case s
    }
}
extension Bank.Account: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.settled] = self.settled
        js[.b] = self.b
        js[.c] = self.c
        js[.d] = self.d
        js[.e] = self.e
        js[.f] = self.f
        js[.i] = self.i
        js[.s] = self.s
    }
}
extension Bank.Account: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            settled: try js[.settled].decode(),
            b: try js[.b]?.decode() ?? 0,
            c: try js[.c]?.decode() ?? 0,
            d: try js[.d]?.decode() ?? 0,
            e: try js[.e]?.decode() ?? 0,
            f: try js[.f]?.decode() ?? 0,
            i: try js[.i]?.decode() ?? 0,
            s: try js[.s]?.decode() ?? 0,
        )
    }
}
