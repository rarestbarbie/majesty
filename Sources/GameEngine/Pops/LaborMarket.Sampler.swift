import Random

extension LaborMarket {
    struct Sampler: ~Copyable {
        private var pops: [(index: Int, unemployed: Int64)]

        init(pops: [(index: Int, unemployed: Int64)]) {
            self.pops = pops
        }
    }
}
extension LaborMarket.Sampler {
    private func reassign(slots: Int, using random: inout PseudoRandom) -> [Int] {
        let unemployed: Int64 = self.pops.reduce(0) { $0 + $1.unemployed }

        var samples: [Int64] = (0 ..< slots).map {
            _ in .random(in: 0 ..< unemployed, using: &random.generator)
        }

        samples.sort()

        var eligible: [Int] = []
        ;   eligible.reserveCapacity(slots)

        var sorted: [Int64].Iterator = samples.makeIterator()
        var next: Int64? = sorted.next()
        var stop: Int64 = 0

        // the `index` is the index of the pop in the `pops` array,
        // not the index of the pop in the global game state table
        outer:
        for (index, (_, size)): (Int, (Int, unemployed: Int64)) in zip(
                self.pops.indices,
                self.pops
            ) {
            stop += size

            while let current: Int64 = next {
                guard current < stop else {
                    // move to the next pop
                    continue outer
                }
                // if a pop is large, this could add it to the
                // list multiple times, which is what we want
                eligible.append(index)
                next = sorted.next()
            }

            break
        }

        return eligible
    }
}
extension LaborMarket.Sampler {
    consuming func match(
        offers: inout [PopJobOfferBlock],
        random: inout PseudoRandom,
        mode: LaborMarketPolicy,
        post: (PopJobOffer, Int, Int64) -> ()
    ) {
        let eligible: [Int]?
        switch mode {
        case .DEI:
            /// We iterate through the pops for as many times as there are job offers. This
            /// means pops near the front of the list are more likely to be visited multiple
            /// times. However, since the pop index array is shuffled, this is fair over time.
            eligible = nil
        case .MajorityPreference:
            eligible = self.reassign(slots: offers.count, using: &random)
        }
        let candidates: Int = self.pops.count
        let iterations: Int = offers.count
        var iteration: Int = 0
        while let i: Int = offers.indices.last, iteration < iterations {
            let block: PopJobOfferBlock = offers[i]
            let match: (id: Int, (count: Int64, remaining: PopJobOfferBlock?))? = {
                $0.unemployed > 0 ? ($0.index, block.matched(with: &$0.unemployed)) : nil
            } (&self.pops[eligible?[iteration] ?? iteration % candidates])

            iteration += 1

            guard
            let (pop, (count, remaining)): (Int, (Int64, PopJobOfferBlock?)) = match else {
                // Pop has no more unemployed members.
                continue
            }

            if  let remaining: PopJobOfferBlock {
                offers[i] = remaining
            } else {
                offers.removeLast()
            }

            post(block.job, pop, count)
        }
    }
}
