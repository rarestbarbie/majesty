extension Bank {
    struct Transfers {
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
        /// Capital gains
        var j: Int64

        init(
            s: Int64 = 0,
            c: Int64 = 0,
            w: Int64 = 0,
            i: Int64 = 0,
            e: Int64 = 0,
            j: Int64 = 0
        ) {
            self.s = s
            self.c = c
            self.w = w
            self.i = i
            self.e = e
            self.j = j
        }
    }
}
