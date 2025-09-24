struct CashTransfers {
    /// Subsidies.
    var s: Int64
    /// Salaries, negative if salaries are owed.
    var c: Int64
    /// Wages, negative if wages are owed.
    var w: Int64
    /// Interest and dividends, negative if owed.
    var i: Int64

    init(
        s: Int64 = 0,
        c: Int64 = 0,
        w: Int64 = 0,
        i: Int64 = 0,
    ) {
        self.s = s
        self.c = c
        self.w = w
        self.i = i
    }
}
