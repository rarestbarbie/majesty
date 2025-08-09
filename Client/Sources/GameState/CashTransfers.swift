struct CashTransfers {
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

    init(
        b: Int64 = 0,
        v: Int64 = 0,
        r: Int64 = 0,
        s: Int64 = 0,
        c: Int64 = 0,
        w: Int64 = 0,
        i: Int64 = 0,
    ) {
        self.b = b
        self.v = v
        self.r = r
        self.s = s
        self.c = c
        self.w = w
        self.i = i
    }
}
