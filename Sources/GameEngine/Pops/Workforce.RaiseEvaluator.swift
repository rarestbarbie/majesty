extension Workforce {
    struct RaiseEvaluator {
        private let q: Int
        private let r: Int
    }
}
extension Workforce.RaiseEvaluator {
    static var pF: Int { 8 }

    init(employers: Int) {
        /// The last `q` factories will always raise wages. The next factory after the first
        /// `q` will raise wages with probability `r / 8`.
        let (q, r): (Int, remainder: Int) = employers.quotientAndRemainder(dividingBy: Self.pF)
        self.init(q: q, r: r)
    }
}
extension Workforce.RaiseEvaluator {
    func pf(position: Int) -> Int {
        switch position {
        case 0 ..< self.q: Self.pF
        case self.q: self.r
        case _: 0
        }
    }
}
