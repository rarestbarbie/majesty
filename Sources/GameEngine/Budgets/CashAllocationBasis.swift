struct CashAllocationBasis {
    let l: Int64
    let e: Int64
    let x: Int64

    private init(l: Int64, e: Int64, x: Int64) {
        self.l = l
        self.e = e
        self.x = x
    }
}
extension CashAllocationBasis {
    /// new businesses have no other expenses, so they should invest more in construction
    static var businessNew: Self { .init(l: 7, e: 30, x: 45) }
    /// currently the same as consumer basis
    static var business: Self { .init(l: 7, e: 30, x: 365) }
    static var consumer: Self { .init(l: 7, e: 30, x: 365) }

    /// buybacks, currently constant, but could be dynamic in the future
    var y: Int64 { 365 }

    static func adjust(liquidity: Int64, assets: Int64) -> Int64 {
        /// if the stockpile is expanded sharply, that makes the next day’s balance look
        /// artificially low, so we need to account for that when calculating budgets
        /// as long as the `d` vector is reasonably sized (less than 75 percent of funds),
        /// this will not cause overspending
        return liquidity + min(assets, liquidity / 4)
    }
}
