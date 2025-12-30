extension LaborMarket {
    struct Supply<Key>: ~Copyable where Key: Hashable {
        private var pops: [Key: [(Int, Int64)]]

        init(pops: [Key: [(Int, Int64)]]) {
            self.pops = pops
        }
    }
}
extension LaborMarket.Supply {
    mutating func pull(_ key: Key) -> LaborMarket.Sampler? {
        {
            if  let pops: [(Int, Int64)] = $0 {
                $0 = []
                return .init(pops: pops)
            } else {
                return nil
            }
        } (&self.pops[key])
    }
}
